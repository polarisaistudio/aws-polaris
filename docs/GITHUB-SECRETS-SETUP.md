# GitHub Secrets Setup for polarisaistudio.com

This guide shows you exactly how to configure GitHub Secrets for the email forwarding deployment.

## Required GitHub Secrets

You need to create **4 secrets** in your GitHub repository.

## Step-by-Step Instructions

### 1. Navigate to GitHub Secrets

1. Go to your GitHub repository: `https://github.com/YOUR-USERNAME/aws-polaris`
2. Click **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. You'll see the "Actions secrets and variables" page

---

### 2. Add AWS_ACCESS_KEY_ID

1. Click **New repository secret**
2. **Name**: `AWS_ACCESS_KEY_ID`
3. **Secret**: Paste your AWS Access Key ID from IAM user `github-actions`
   - Example: `AKIAIOSFODNN7EXAMPLE`
   - Get this from AWS Console → IAM → Users → github-actions → Security credentials → Access keys
4. Click **Add secret**

---

### 3. Add AWS_SECRET_ACCESS_KEY

1. Click **New repository secret**
2. **Name**: `AWS_SECRET_ACCESS_KEY`
3. **Secret**: Paste your AWS Secret Access Key
   - Example: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
   - You saved this when creating the access key (check your password manager)
4. Click **Add secret**

---

### 4. Add AWS_REGION

1. Click **New repository secret**
2. **Name**: `AWS_REGION`
3. **Secret**: `us-east-1`
   - Must be one of: `us-east-1`, `us-west-2`, or `eu-west-1` (SES receiving regions)
4. Click **Add secret**

---

### 5. Add TF_VARS (Terraform Variables)

1. Click **New repository secret**
2. **Name**: `TF_VARS`
3. **Secret**: Copy the **entire content** below:

```hcl
domain_name = "polarisaistudio.com"
aws_region  = "us-east-1"

forward_mapping = {
  "info"    = "polarisaistudio@gmail.com"
  "contact" = "polarisaistudio@gmail.com"
  "support" = "polarisaistudio@gmail.com"
  "admin"   = "polarisaistudio@gmail.com"
}

catch_all_forward = ""

from_email = "noreply@polarisaistudio.com"

github_pages_repo = "polarisaistudio.github.io"

email_retention_days = 7

s3_bucket_prefix = "ses-email-forwarder"

ses_rule_set_name = "email-forwarding-rules"

tags = {
  Environment = "production"
  Project     = "EmailForwarding"
  ManagedBy   = "Terraform"
  Domain      = "polarisaistudio.com"
}
```

4. Click **Add secret**

**Important**: Copy the entire block above, including all the variables and values.

---

## Verify Your Secrets

After adding all 4 secrets, you should see:

```
Repository secrets (4)

AWS_ACCESS_KEY_ID          Updated now
AWS_SECRET_ACCESS_KEY      Updated now
AWS_REGION                 Updated now
TF_VARS                    Updated now
```

## Alternative: Use terraform.tfvars.production File

Instead of copying from above, you can:

1. Open `terraform.tfvars.production` in this repository
2. Copy the entire file content
3. Paste it into the `TF_VARS` secret

Both methods are equivalent.

---

## Security Notes

✅ **Good practices**:

- Secrets are encrypted by GitHub
- Secrets are automatically masked in workflow logs
- Secrets are only available to workflows in this repository
- Only repository admins can view/edit secrets

⚠️ **Important warnings**:

- Never commit `terraform.tfvars` to Git
- Never share your AWS access keys
- Rotate access keys every 90 days
- Enable MFA on the `github-actions` IAM user

---

## Testing the Secrets

After adding the secrets, you can test them:

1. Create a test branch:

   ```bash
   git checkout -b test-secrets
   git push origin test-secrets
   ```

2. Create a Pull Request to `main`

3. GitHub Actions will automatically run and use your secrets

4. Check the workflow logs - secrets will appear as `***`

---

## Troubleshooting

### Secret not working?

- Verify the secret name is **exactly** as shown (case-sensitive)
- Check for extra spaces or line breaks
- Re-create the secret if needed

### Workflow can't find secret?

- Ensure you're on a branch that triggers the workflow
- Check that the workflow file references the correct secret names
- Verify Actions are enabled in repository settings

### AWS authentication fails?

- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
- Check the IAM user has `AdministratorAccess` policy attached
- Ensure the access key is active (not deleted)

---

## Next Steps

After configuring all secrets:

1. ✅ Secrets are configured
2. ✅ Push code to GitHub
3. ✅ Create Pull Request
4. ✅ GitHub Actions will run automatically
5. ✅ Review Terraform plan in PR
6. ✅ Merge to deploy

See [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) for the complete deployment process.
