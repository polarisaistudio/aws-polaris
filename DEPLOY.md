# Deployment Guide

This project includes automated deployment scripts that manage the Terraform build/apply lifecycle with intelligent change detection.

## Deployment Scripts

### `deploy.sh` - Interactive Local Deployment

Interactive deployment script with user confirmation before applying changes.

**Usage:**
```bash
./deploy.sh
```

**Features:**
- ✅ Initializes and validates Terraform configuration
- ✅ Generates execution plan with visual summaries (table and tree views)
- ✅ Detects if there are no changes and skips apply
- ✅ Prompts for user confirmation before applying
- ✅ Uses `tf-summarize` for enhanced plan visualization
- ✅ Color-coded output for easy reading

**Requirements:**
- Terraform
- Go (for Lambda builds)
- jq
- tf-summarize (optional, install with: `brew install tf-summarize`)

**Workflow:**
1. Initialize Terraform (`terraform init -upgrade`)
2. Validate configuration (`terraform validate`)
3. Generate plan (`terraform plan -out=tfplan`)
4. Display plan summary (table + tree views)
5. Check for changes
6. If changes detected, prompt user for confirmation
7. Apply changes if confirmed
8. Cleanup plan file

---

### `deploy-ci.sh` - Non-Interactive CI/CD Deployment

Automated deployment script for CI/CD pipelines (GitHub Actions, GitLab CI, etc.)

**Usage:**
```bash
./deploy-ci.sh
```

**Features:**
- ✅ Non-interactive (no user prompts)
- ✅ Automatically applies changes if detected
- ✅ Skips apply if no changes detected
- ✅ Enhanced logging for CI/CD environments
- ✅ Exit codes for pipeline integration

**Workflow:**
1. Initialize Terraform
2. Validate configuration
3. Generate plan
4. Display plan summary
5. Check for changes
6. Auto-apply if changes detected (no confirmation)
7. Exit with appropriate status code

---

## How It Works

### Change Detection

Both scripts use the following logic to determine if changes exist:

```bash
CHANGES=$(terraform show -json tfplan | jq -r '.resource_changes // [] | length')

if [ "$CHANGES" -eq 0 ]; then
    echo "No changes detected!"
    echo "Skipping apply step."
    exit 0
fi
```

This ensures that:
- **No changes** = Skip apply, exit gracefully
- **Changes detected** = Proceed with apply (with or without confirmation)

### Plan Visualization with tf-summarize

The scripts use `tf-summarize` to provide clear, readable plan summaries:

**Table View:**
```
┌───────────┬───────┐
│  Action   │ Count │
├───────────┼───────┤
│ Add       │     2 │
│ Change    │     1 │
│ Destroy   │     0 │
│ Recreate  │     2 │
└───────────┴───────┘
```

**Tree View:**
```
module.email_forwarding
  ├── aws_lambda_function.forwarder (recreate)
  ├── null_resource.lambda_build (recreate)
  └── aws_ses_receipt_rule.forward (update)
```

---

## GitHub Actions Integration

The `.github/workflows/terraform.yml` workflow uses `deploy-ci.sh` for automated deployments:

```yaml
- name: Deploy with CI Script
  run: ./deploy-ci.sh
```

**Workflow Steps:**
1. **Validate** - Runs on all PRs and pushes
2. **Build Lambda** - Compiles Go Lambda function
3. **Plan** - Generates plan on PRs with tf-summarize output
4. **Apply** - Runs `deploy-ci.sh` on main branch pushes

**Plan Summary in PRs:**
- Automatically posted to GitHub Step Summary
- Shows both table and tree views
- Helps reviewers understand infrastructure changes

---

## Local Development Workflow

### Quick Deploy
```bash
./deploy.sh
```

### Deploy Without Confirmation (use with caution)
```bash
./deploy-ci.sh
```

### Manual Terraform Commands
```bash
# Initialize
terraform init

# Plan with visualization
terraform plan -out=tfplan
tf-summarize tfplan           # table view
tf-summarize -tree tfplan     # tree view

# Apply
terraform apply tfplan
```

---

## Build Management

The deployment scripts automatically handle Lambda builds through Terraform:

### How Lambda Builds Work

1. **Trigger Detection** - Terraform detects changes in:
   - Go source files (`*.go`)
   - Go dependencies (`go.mod`, `go.sum`)
   - Build configuration (`Makefile`)
   - Environment variables
   - Architecture settings (arm64/x86_64)

2. **Automated Build** - `null_resource.lambda_build` runs:
   ```bash
   make build
   ```

3. **Packaging** - `archive_file` creates `lambda.zip`

4. **Deployment** - Lambda function updated with new code

### Manual Lambda Build
```bash
cd lambda/forwarder
make build
```

---

## Environment Configuration

### AWS Credentials

**Local Deployment:**
```bash
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_DEFAULT_REGION=us-west-2
```

Or use AWS profiles:
```bash
export AWS_PROFILE=my-profile
```

**GitHub Actions:**
Set these secrets in your repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### Terraform Variables

All variables have defaults in `variables.tf`. No `terraform.tfvars` file needed for standard deployment.

To override defaults, create `terraform.tfvars`:
```hcl
domain_name = "example.com"
forward_mapping = {
  "hello" = "user@example.com"
}
```

---

## Troubleshooting

### tf-summarize not found
```bash
# macOS
brew install tf-summarize

# Linux
wget https://github.com/dineshba/tf-summarize/releases/latest/download/tf-summarize_linux_amd64.tar.gz
tar -xzf tf-summarize_linux_amd64.tar.gz
sudo mv tf-summarize /usr/local/bin/
```

### jq not found
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

### Lambda build fails
```bash
# Install Go dependencies
cd lambda/forwarder
go mod download

# Verify Go version
go version  # Should be 1.21 or higher
```

### Plan shows no changes but infrastructure is different
```bash
# Force refresh
terraform init -upgrade
terraform plan -refresh=true
```

---

## Exit Codes

Both scripts use standard exit codes:
- `0` - Success (applied or no changes)
- `1` - Error (validation, plan, or apply failed)

This makes them compatible with CI/CD pipelines and automation tools.

---

## Best Practices

1. **Always review the plan** before applying changes
2. **Use `deploy.sh`** for local development (interactive)
3. **Use `deploy-ci.sh`** in automation (non-interactive)
4. **Check tf-summarize output** to understand infrastructure changes
5. **Keep `terraform.tfvars` out of version control** (use `.gitignore`)
6. **Use GitHub Actions** for production deployments
7. **Test locally first** before pushing to main branch

---

## Related Documentation

- [SETUP.md](SETUP.md) - Initial GitHub Actions setup
- [LOCAL-DEPLOYMENT.md](LOCAL-DEPLOYMENT.md) - Local Terraform setup
- [GITHUB-SECRETS-SETUP.md](GITHUB-SECRETS-SETUP.md) - GitHub Secrets configuration
