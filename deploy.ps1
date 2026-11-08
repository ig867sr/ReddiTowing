[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$Bucket = 'www.redditow.com',
    [string]$Region = 'us-west-1',
    [string]$Profile = 'ScottAdmin',
    [string]$DistributionId = 'E30BUVIUBO927S'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$indexPath = Join-Path $PSScriptRoot 'index.html'
if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    throw "Website homepage not found: $indexPath"
}
$logoPath = Join-Path $PSScriptRoot 'assets\logos\option-3-flatbed.svg'
if (-not (Test-Path -LiteralPath $logoPath -PathType Leaf)) {
    throw "Website logo not found: $logoPath"
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI was not found. Install AWS CLI v2 and try again.'
}

$identityOutput = & aws sts get-caller-identity --profile $Profile --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    throw "Could not verify AWS identity with profile '$Profile'. Authenticate with AWS and retry."
}
$identity = $identityOutput | ConvertFrom-Json
Write-Host "AWS account: $($identity.Account)"
Write-Host "AWS identity: $($identity.Arn)"

& aws s3api head-bucket --bucket $Bucket --profile $Profile --region $Region
if ($LASTEXITCODE -ne 0) {
    throw "Cannot access S3 bucket '$Bucket' in region '$Region' with profile '$Profile'."
}

$logoDestination = "s3://$Bucket/assets/logos/option-3-flatbed.svg"
if ($PSCmdlet.ShouldProcess($logoDestination, 'Upload website logo')) {
    & aws s3 cp $logoPath $logoDestination `
        --content-type 'image/svg+xml' `
        --cache-control 'no-cache' `
        --profile $Profile `
        --region $Region
    if ($LASTEXITCODE -ne 0) {
        throw "Upload to '$logoDestination' failed."
    }
}

$indexDestination = "s3://$Bucket/index.html"
if ($PSCmdlet.ShouldProcess($indexDestination, 'Upload index.html')) {
    & aws s3 cp $indexPath $indexDestination `
        --content-type 'text/html; charset=utf-8' `
        --cache-control 'no-cache' `
        --profile $Profile `
        --region $Region
    if ($LASTEXITCODE -ne 0) {
        throw "Upload to '$indexDestination' failed."
    }
}

if ($DistributionId) {
    if ($PSCmdlet.ShouldProcess("CloudFront distribution $DistributionId", 'Invalidate homepage cache')) {
        & aws cloudfront create-invalidation `
            --distribution-id $DistributionId `
            --paths '/index.html' '/' '/assets/logos/option-3-flatbed.svg' `
            --profile $Profile
        if ($LASTEXITCODE -ne 0) {
            throw "CloudFront invalidation failed for distribution '$DistributionId'."
        }
    }
}
elseif (-not $WhatIfPreference) {
    Write-Host 'No CloudFront distribution ID supplied; no CloudFront invalidation was requested.'
}
