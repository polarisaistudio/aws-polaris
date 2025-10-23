#!/bin/bash
set -e

echo "========================================="
echo "AWS Email Forwarding Setup Script"
echo "========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform >= 1.0"
    exit 1
fi
echo "✅ Terraform found: $(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)"

if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go >= 1.21"
    exit 1
fi
echo "✅ Go found: $(go version | awk '{print $3}')"

if ! command -v make &> /dev/null; then
    echo "❌ Make is not installed. Please install make"
    exit 1
fi
echo "✅ Make found"

if ! command -v aws &> /dev/null; then
    echo "⚠️  AWS CLI is not installed (optional but recommended)"
else
    echo "✅ AWS CLI found: $(aws --version | awk '{print $1}')"
fi

echo ""

# Check for terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found!"
    echo ""
    echo "Please create terraform.tfvars from the example:"
    echo "  cp terraform.tfvars.example terraform.tfvars"
    echo "  # Edit terraform.tfvars with your configuration"
    exit 1
fi
echo "✅ terraform.tfvars found"

echo ""
echo "========================================="
echo "Building Lambda Function"
echo "========================================="
cd lambda/forwarder
make clean
make build
cd ../..
echo "✅ Lambda function built successfully"

echo ""
echo "========================================="
echo "Initializing Terraform"
echo "========================================="
terraform init

echo ""
echo "========================================="
echo "Validating Configuration"
echo "========================================="
terraform validate

echo ""
echo "========================================="
echo "Planning Deployment"
echo "========================================="
terraform plan

echo ""
echo "========================================="
echo "Ready to Deploy!"
echo "========================================="
echo ""
echo "Review the plan above. To deploy, run:"
echo "  terraform apply"
echo ""
echo "After deployment:"
echo "  1. Update your domain's nameservers (shown in outputs)"
echo "  2. Wait 24-48 hours for DNS propagation"
echo "  3. Verify recipient email addresses in SES console (if in sandbox)"
echo "  4. Request SES production access for unrestricted sending"
echo ""
