# GitHub Actions CI/CD Setup Guide for AWS Email Forwarding

This guide provides step-by-step instructions for securely setting up GitHub Actions with your AWS account to deploy the email forwarding infrastructure.

## Table of Contents

- [Security Best Practices](#security-best-practices)
- [Prerequisites](#prerequisites)
- [Step 1: Create IAM User for GitHub Actions](#step-1-create-iam-user-for-github-actions)
- [Step 2: Attach Administrator Policy](#step-2-attach-administrator-policy)
- [Step 3: Generate Access Keys](#step-3-generate-access-keys)
- [Step 4: Configure GitHub Secrets](#step-4-configure-github-secrets)
- [Step 5: Set Up Terraform Backend (Optional)](#step-5-set-up-terraform-backend-optional)
- [Step 6: Configure terraform.tfvars](#step-6-configure-terraformtfvars)
- [Step 7: Test the Pipeline](#step-7-test-the-pipeline)
- [Step 8: Deploy to Production](#step-8-deploy-to-production)
- [Security Hardening](#security-hardening)
- [Troubleshooting](#troubleshooting)

## Security Best Practices

This setup follows AWS security best practices:

✅ **No Root Account Usage**: Uses dedicated IAM user, not root credentials
✅ **General Admin User**: Single `github-actions` user for all GitHub Actions workflows
✅ **Protected Secrets**: Credentials stored as encrypted secrets in GitHub
✅ **MFA Recommended**: Enable MFA on the IAM user for additional security
✅ **Access Key Rotation**: Regular rotation of access keys (every 90 days recommended)
✅ **Audit Logging**: CloudTrail logs all API calls for compliance

**Note**: This setup uses Administrator access for simplicity and flexibility across multiple projects. If you need stricter permissions, you can create project-specific policies instead.

## Prerequisites

- AWS root account access or IAM admin user
- GitHub repository for this project
- AWS CLI installed (for testing, optional)
- Permissions to create IAM users and policies
- **Existing Route 53 hosted zone** for `polarisaistudio.com` (Terraform will use the existing zone, not create a new one)

## Step 1: Create IAM User for GitHub Actions

### 1.1 Sign in to AWS Console

1. Go to https://console.aws.amazon.com/
2. Sign in with your root account or an admin IAM user
3. Navigate to **IAM** service (search for "IAM" in the top search bar)

### 1.2 Create New IAM User (or Use Existing)

**If you already have a `github-actions` user**, skip to Step 2 to verify permissions.

**To create a new user**:

1. In the IAM dashboard, click **Users** in the left sidebar
2. Click **Create user** button
3. Configure the user:
   - **User name**: `github-actions`
   - **Provide user access to AWS Management Console**: ❌ **Uncheck** (programmatic access only)
4. Click **Next**

### 1.3 Set Permissions (Skip for Now)

1. Select **Attach policies directly**
2. **Do not select any policies yet** (we'll add them in Step 2)
3. Click **Next**

### 1.4 Review and Create

1. Review the configuration
2. Add tags (optional but recommended):
   - Key: `Purpose`, Value: `GitHub Actions`
   - Key: `Project`, Value: `Infrastructure`
   - Key: `Environment`, Value: `Production`
3. Click **Create user**

## Step 2: Attach Administrator Policy

### 2.1 Attach AdministratorAccess Policy

This gives the `github-actions` user full access to manage AWS resources across all your projects.

1. Go to **IAM** → **Users**
2. Click on the `github-actions` user
3. Click the **Permissions** tab
4. Click **Add permissions** → **Attach policies directly**
5. Search for `AdministratorAccess`
6. Check the box next to **AdministratorAccess** (AWS managed policy)
7. Click **Add permissions**

### 2.2 Verify Permissions

1. You should see **AdministratorAccess** listed under **Permissions policies**
2. This policy grants full access to all AWS services and resources

**Alternative: Use Custom Policy (Optional)**

If you prefer more granular control, you can create a custom policy using `iam-policy.json` from this repository. However, for a general GitHub Actions user managing multiple projects, AdministratorAccess is simpler and more flexible.

## Step 3: Generate Access Keys

### 3.1 Create Access Key (If Needed)

**If you already have access keys for this user**, you can reuse them or create new ones.

1. Still on the `github-actions` user page
2. Click the **Security credentials** tab
3. Scroll down to **Access keys** section
4. Click **Create access key**
5. Select use case: **Application running outside AWS**
6. Check "I understand the above recommendation and want to proceed"
7. Click **Next**

### 3.2 Set Description Tag

1. **Description tag**: `GitHub Actions - General Use`
2. Click **Create access key**

### 3.3 Save Credentials Securely

⚠️ **CRITICAL**: This is the ONLY time you can view the secret access key!

1. **Copy both values** immediately:
   - **Access key ID**: `AKIA...`
   - **Secret access key**: `wJalrXUtn...`
2. Store them in a password manager (1Password, LastPass, etc.)
3. Click **Done**

🔒 **Never commit these credentials to Git or share them publicly!**

## Step 4: Configure GitHub Secrets

### 4.1 Navigate to GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 4.2 Add AWS_ACCESS_KEY_ID

1. **Name**: `AWS_ACCESS_KEY_ID`
2. **Secret**: Paste your Access Key ID (e.g., `AKIAIOSFODNN7EXAMPLE`)
3. Click **Add secret**

### 4.3 Add AWS_SECRET_ACCESS_KEY

1. Click **New repository secret** again
2. **Name**: `AWS_SECRET_ACCESS_KEY`
3. **Secret**: Paste your Secret Access Key
4. Click **Add secret**

### 4.4 Add AWS_REGION

1. Click **New repository secret** again
2. **Name**: `AWS_REGION`
3. **Secret**: Your AWS region (e.g., `us-east-1`, `us-west-2`, or `eu-west-1`)
4. Click **Add secret**

### 4.5 Verify Secrets

You should now have three secrets configured:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

🔒 **Note**: GitHub automatically masks these values in workflow logs.

## Step 5: Set Up Terraform Backend (Optional)

For production environments, it's recommended to use S3 backend for Terraform state.

### 5.1 Create S3 Bucket for State

Using AWS CLI or Console:

```bash
# Set your desired bucket name (must be globally unique)
BUCKET_NAME="terraform-state-email-forwarder-$(date +%s)"

# Create bucket
aws s3 mb s3://${BUCKET_NAME} --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    BlockPublicAcls=true,\
IgnorePublicAcls=true,\
BlockPublicPolicy=true,\
RestrictPublicBuckets=true
```

### 5.2 Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock-email-forwarder \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 5.3 Update versions.tf

Add backend configuration to `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "your-terraform-state-bucket-name"
    key            = "email-forwarder/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-email-forwarder"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
```

### 5.4 IAM Permissions

Since the `github-actions` user has AdministratorAccess, it already has permissions to manage S3 and DynamoDB for state storage. No additional policy changes needed.

## Step 6: Configure terraform.tfvars

### 6.1 Create terraform.tfvars Locally

**Important**: Do NOT commit `terraform.tfvars` to GitHub (it's already in `.gitignore`)

Create the file locally with your configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
domain_name = "polarisaistudio.com"
aws_region  = "us-east-1"

forward_mapping = {
  "info"    = "polarisaistudio@gmail.com"
  "contact" = "polarisaistudio@gmail.com"
  "support" = "polarisaistudio@gmail.com"
}

catch_all_forward = ""

tags = {
  Environment = "production"
  Project     = "EmailForwarding"
  ManagedBy   = "Terraform"
}
```

### 6.2 Option A: Store as GitHub Secret (Recommended)

To use terraform.tfvars in GitHub Actions:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. **Name**: `TF_VARS`
4. **Secret**: Paste the entire contents of your `terraform.tfvars` file
5. Click **Add secret**

The GitHub Actions workflow will automatically use this secret.

### 6.2 Option B: Manual Deployment Only

If you prefer to deploy manually and not use GitHub Actions, just keep `terraform.tfvars` locally (don't commit it).

## Step 7: Test the Pipeline

### 7.1 Create a Test Branch

```bash
git checkout -b test-github-actions
git push origin test-github-actions
```

### 7.2 Create a Pull Request

1. In GitHub, go to **Pull requests**
2. Click **New pull request**
3. Base branch: `main`
4. Compare branch: `test-github-actions`
5. Click **Create pull request**

### 7.3 Monitor the Workflow

1. The workflow should automatically start
2. Click the **Actions** tab to view progress
3. Verify these jobs complete successfully:
   - ✅ `validate` - Terraform validation
   - ✅ `build-lambda` - Go compilation
   - ✅ `plan` - Terraform plan

### 7.4 Review the Plan

1. Click on the `plan` job in the Actions tab
2. Review the Terraform plan output
3. Verify it shows the resources that will be created:
   - Route 53 hosted zone
   - SES domain identity
   - S3 bucket
   - Lambda function
   - IAM roles and policies

## Step 8: Deploy to Production

### 8.1 Merge to Main

1. If the plan looks correct, approve and merge the PR
2. This will trigger a new workflow on the `main` branch

### 8.2 Manual Apply

The `apply` job is set to manual approval for safety:

1. Go to **Actions** tab
2. Find the workflow run for the `main` branch
3. Click on the workflow
4. Click **Review deployments**
5. Check the **production** environment
6. Click **Approve and deploy**

### 8.3 Monitor Deployment

1. Watch the `apply` job logs
2. It will show all resources being created
3. The job should complete successfully in ~5-10 minutes

### 8.4 Retrieve Outputs

After successful deployment:

1. Check the job logs for Terraform outputs
2. DNS records (MX, SPF, DKIM, DMARC) have been added to the existing `polarisaistudio.com` hosted zone
3. No nameserver changes needed (using existing hosted zone)
4. Follow the post-deployment steps in README.md

## Security Hardening

### Enable MFA for IAM User

For additional security, enable MFA on the IAM user:

1. Go to **IAM** → **Users** → `github-actions`
2. Click **Security credentials** tab
3. In **Multi-factor authentication (MFA)**, click **Assign MFA device**
4. Choose **Virtual MFA device**
5. Use an authenticator app (Google Authenticator, Authy, etc.)
6. Follow the setup wizard

⚠️ **Note**: MFA on IAM users doesn't affect programmatic access via access keys.

### Rotate Access Keys Regularly

Set a reminder to rotate access keys every 90 days:

1. Create new access key in AWS Console
2. Update GitHub Secrets with new credentials
3. Test workflow with new credentials
4. Delete old access key

### Enable CloudTrail Logging

Ensure CloudTrail is enabled to audit all API calls:

1. Go to **CloudTrail** in AWS Console
2. Create a trail if not already enabled
3. Enable logging for all regions
4. Review logs periodically for suspicious activity

### Use Environment Protection Rules

Add approval requirements in GitHub:

1. Go to **Settings** → **Environments**
2. Click **production**
3. Check **Required reviewers**
4. Add team members who must approve deployments
5. Save protection rules

### Use OpenID Connect (OIDC) Instead of Access Keys (Advanced)

For even better security, use GitHub's OIDC provider instead of long-lived access keys:

- [GitHub Documentation: Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

This eliminates the need for access keys entirely.

## Troubleshooting

### Workflow Fails with "Access Denied"

**Problem**: IAM user doesn't have sufficient permissions

**Solution**:

1. Verify that **AdministratorAccess** is attached to the `github-actions` user
2. Check IAM → Users → github-actions → Permissions tab
3. If not attached, follow Step 2 to attach the policy
4. Review CloudTrail logs to see which specific API call failed

### "InvalidClientTokenId" Error

**Problem**: Access key is incorrect or not recognized

**Solution**:

1. Verify the access key ID in GitHub Secrets matches AWS
2. Ensure the access key is active (not deleted)
3. Check that you're using the correct AWS account
4. Re-create the secret if necessary

### "SignatureDoesNotMatch" Error

**Problem**: Secret access key is incorrect

**Solution**:

1. Verify the secret access key in GitHub Secrets
2. Check for extra spaces or line breaks in the secret
3. Regenerate access key if necessary
4. Update GitHub Secret with new value

### Terraform State Lock Error

**Problem**: State is locked from a previous run

**Solution**:

```bash
# Force unlock (use the Lock ID from error message)
terraform force-unlock <lock-id>
```

### S3 Bucket Already Exists

**Problem**: S3 bucket name is not globally unique

**Solution**:

1. Change the `s3_bucket_prefix` variable in terraform.tfvars
2. S3 bucket names must be globally unique across all AWS accounts

### Lambda Build Fails

**Problem**: Go build errors or missing dependencies

**Solution**:

1. Ensure `go.mod` is up to date
2. Run `go mod tidy` locally and commit changes
3. Check that Go version in workflow matches `go.mod`

### Workflow Not Triggering

**Problem**: GitHub Actions workflow doesn't run

**Solution**:

1. Check that `.github/workflows/terraform.yml` exists
2. Verify workflow syntax using GitHub's workflow editor
3. Check Actions tab for error messages
4. Ensure Actions are enabled in repository settings

## Next Steps

After successful deployment:

1. ✅ Verify DNS records were added to Route 53 (check the hosted zone for `polarisaistudio.com`)
2. ✅ Wait for DNS propagation (~15 minutes, records added to existing zone)
3. ✅ Verify SES domain in AWS Console
4. ✅ If in SES sandbox, verify recipient email addresses
5. ✅ Request SES production access for unrestricted sending
6. ✅ Test email forwarding (send to `info@polarisaistudio.com`, `contact@polarisaistudio.com`, etc.)
7. ✅ Monitor CloudWatch logs for the Lambda function

**Note**: Since we're using an existing hosted zone, nameserver changes are NOT needed. The domain is already configured.

## Additional Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS SES Documentation](https://docs.aws.amazon.com/ses/)

## Support

For issues or questions:

- Check the workflow logs in GitHub Actions
- Review CloudTrail logs in AWS Console
- Verify IAM permissions match the AdministratorAccess policy
- Check terraform state for inconsistencies
