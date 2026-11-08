# Reddi Towing website

Static website for Reddi Towing, Inc. The production files are in the S3 bucket
`www.redditow.com` in `us-west-1`. The site should be served through CloudFront
with HTTPS and a private S3 origin; Route 53 hosts the `redditow.com` zone.

The homepage uses relative image URLs so CloudFront can serve the page and the
existing `images/` objects from the same origin.

## Deploy the homepage

The deployment script uploads `index.html` and the SVG logo at
`assets/logos/option-3-flatbed.svg`; it does not delete or replace the existing
images. When a CloudFront distribution ID is configured, it also invalidates
the homepage and logo paths so visitors receive the update.

Requirements:

- AWS CLI v2
- An authenticated AWS SSO profile with permission to upload to the bucket and
  invalidate its CloudFront distribution

```powershell
aws sso login --profile ScottAdmin
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

The script verifies the AWS identity and bucket access, then asks before
uploading. To check the planned upload without changing anything:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1 -WhatIf
```

AWS credentials are not stored in this repository. Never commit credentials,
access keys, or local AWS configuration.

## Connect to GitHub

After creating a private GitHub repository for this project, connect and push
it:

```powershell
git remote add origin https://github.com/YOUR-OWNER/ReddiTowing.git
git push -u origin main
```
