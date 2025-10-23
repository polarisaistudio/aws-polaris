# Quick Start Guide

Choose your deployment method:

## Option 1: GitHub CI/CD (Recommended for Production)

**Best for**: Production deployments, team collaboration, automated workflows

1. **Follow SETUP.md** for complete GitHub CI/CD configuration
2. **Prerequisites**: AWS root account, GitHub repository
3. **Time**: ~30 minutes for initial setup
4. **Benefits**:
   - Automated deployment pipeline
   - Code review process
   - Version control
   - Audit trail

**Quick Steps**:

```bash
# 1. Set up IAM user and credentials (see SETUP.md)
# 2. Configure GitHub CI/CD variables
# 3. Push code to GitHub
git push origin main

# 4. Pipeline runs automatically
# 5. Manually approve 'apply' job in GitHub UI
```

📖 **Full Guide**: See [SETUP.md](SETUP.md)

---

## Option 2: Local Deployment (Quick Testing)

**Best for**: Local testing, development, learning

1. **Prerequisites**: AWS CLI configured, Terraform, Go, Make
2. **Time**: ~10 minutes
3. **Benefits**: Fast iteration, local control

**Quick Steps**:

```bash
# 1. Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your domain and email mappings

# 2. Run the automated setup script
./setup.sh

# 3. Review the plan, then apply
terraform apply

# 4. Update your domain's nameservers with the output values
```

📖 **Full Guide**: See [README.md](README.md)

---

## Option 3: GitHub Actions (Alternative CI/CD)

**Best for**: Projects already using GitHub

1. **Prerequisites**: GitHub repository, AWS account
2. **Workflow**: `.github/workflows/terraform.yml` already configured
3. **Setup**: Similar to GitHub (use GitHub Secrets instead)

**Quick Steps**:

```bash
# 1. Create IAM user (follow SETUP.md steps 1-3)

# 2. Add GitHub Secrets
# Repository Settings → Secrets and variables → Actions
# Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION

# 3. Push to GitHub
git push origin main

# 4. Workflow runs automatically on PRs and main branch
```

---

## What Happens After Deployment?

Regardless of deployment method:

1. ✅ AWS infrastructure is created (Route 53, SES, S3, Lambda)
2. ⏳ Update domain nameservers (from Terraform outputs)
3. ⏳ Wait 24-48 hours for DNS propagation
4. ✅ Verify SES domain in AWS Console
5. ✅ Test email forwarding

---

## File Guide

| File                              | Purpose                  | When to Use                          |
| --------------------------------- | ------------------------ | ------------------------------------ |
| `README.md`                       | Complete documentation   | Understanding the project            |
| `SETUP.md`                        | GitHub CI/CD setup guide | Setting up automated deployment      |
| `QUICKSTART.md`                   | This file                | Choosing deployment method           |
| `terraform.tfvars.example`        | Configuration template   | Creating your config                 |
| `iam-policy.json`                 | IAM admin policy         | Reference (uses AdministratorAccess) |
| `.github-actions.yml`                  | GitHub pipeline          | Automated GitHub deployment          |
| `.github/workflows/terraform.yml` | GitHub Actions           | Automated GitHub deployment          |
| `setup.sh`                        | Local setup helper       | Quick local deployment               |

---

## Support & Troubleshooting

- **GitHub CI Issues**: See SETUP.md → Troubleshooting section
- **Terraform Errors**: See README.md → Troubleshooting section
- **Go Build Issues**: Run `cd lambda/forwarder && make clean && make build`
- **AWS Permissions**: Check CloudTrail logs for denied API calls

---

## Quick Command Reference

```bash
# Build Lambda function
cd lambda/forwarder && make build

# Validate Terraform
terraform fmt -check -recursive
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output

# Check Lambda logs
aws logs tail /aws/lambda/ses-email-forwarder-forwarder --follow

# Destroy infrastructure
terraform destroy
```

---

## Security Checklist

- [ ] IAM user created (not using root credentials)
- [ ] AdministratorAccess policy attached (or custom policy if preferred)
- [ ] Access keys stored securely (password manager)
- [ ] GitHub/GitHub variables are protected and masked
- [ ] `.gitignore` includes `*.tfvars`
- [ ] MFA enabled on IAM user (recommended)
- [ ] Access key rotation scheduled (every 90 days)

---

## Next Steps

After successful deployment:

1. Monitor the first few forwarded emails in CloudWatch Logs
2. Check email deliverability (not going to spam)
3. Set up alerts for Lambda errors
4. Document your specific configuration
5. Schedule access key rotation reminder

---

## Cost Estimate

Monthly cost for typical usage (1,000 emails/month):

- Route 53 Hosted Zone: $0.50
- SES Receiving: $0.10
- SES Sending: $0.10
- S3 Storage: $0.01
- Lambda: Free tier
- **Total: ~$0.72/month**

---

**Ready to deploy?**

- **Production/Team**: Follow [SETUP.md](SETUP.md) for GitHub CI/CD
- **Local/Testing**: Follow [README.md](README.md) for local deployment
- **Need help?**: Check the troubleshooting sections in each guide
