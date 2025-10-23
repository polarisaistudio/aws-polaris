#!/bin/bash
set -e

# Non-interactive deployment script for CI/CD environments
# This script automatically applies changes without user confirmation

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Terraform CI/CD Deployment${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if tf-summarize is installed
if ! command -v tf-summarize &> /dev/null; then
    echo -e "${YELLOW}Warning: tf-summarize not found.${NC}"
    USE_TF_SUMMARIZE=false
else
    USE_TF_SUMMARIZE=true
fi

# Step 1: Initialize Terraform
echo -e "${BLUE}[1/4] Initializing Terraform...${NC}"
terraform init -upgrade
echo ""

# Step 2: Validate configuration
echo -e "${BLUE}[2/4] Validating Terraform configuration...${NC}"
terraform validate
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"
else
    echo -e "${RED}✗ Configuration validation failed${NC}"
    exit 1
fi
echo ""

# Step 3: Generate plan
echo -e "${BLUE}[3/4] Generating Terraform plan...${NC}"
terraform plan -out=tfplan
PLAN_EXIT_CODE=$?

if [ $PLAN_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Plan generated successfully${NC}"
else
    echo -e "${RED}✗ Plan generation failed${NC}"
    exit 1
fi
echo ""

# Display plan summary with tf-summarize
if [ "$USE_TF_SUMMARIZE" = true ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Plan Summary (Table View)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    tf-summarize tfplan
    echo ""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Plan Summary (Tree View)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    tf-summarize -tree tfplan
    echo ""
fi

# Check if there are any changes
CHANGES=$(terraform show -json tfplan | jq -r '.resource_changes // [] | length')

if [ "$CHANGES" -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  No changes detected!${NC}"
    echo -e "${GREEN}  Infrastructure is up to date.${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Skipping apply step.${NC}"
    rm -f tfplan
    exit 0
fi

# Step 4: Apply changes (auto-approve for CI/CD)
echo -e "${BLUE}[4/4] Applying Terraform plan...${NC}"
echo -e "${YELLOW}Applying $CHANGES resource change(s) automatically (CI/CD mode).${NC}"
echo ""

terraform apply tfplan

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ Deployment successful!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✗ Deployment failed!${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi

# Cleanup
rm -f tfplan
echo ""
echo -e "${BLUE}Deployment complete.${NC}"
