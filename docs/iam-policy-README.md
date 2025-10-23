# IAM Policy for GitLab CI User

## Current Configuration

The `iam-policy.json` file contains a simple **AdministratorAccess** policy that grants full permissions to all AWS services and resources.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AdministratorAccess",
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

## Recommended Approach

**For most users**: Instead of using this custom policy, simply attach the AWS-managed **AdministratorAccess** policy directly to your `gitlab-ci` IAM user through the AWS Console. This is simpler and doesn't require maintaining a custom policy.

See [SETUP.md](SETUP.md) Step 2 for instructions.

## Why AdministratorAccess?

- **Simplicity**: One policy for all GitLab CI/CD projects
- **Flexibility**: Works across multiple AWS services and projects
- **Maintenance**: No need to update permissions for new services
- **Standard Practice**: Common approach for CI/CD service accounts

## Security Considerations

✅ **Acceptable for CI/CD users** when:
- User has no console access (programmatic only)
- Access keys are protected and masked in GitLab
- MFA is enabled (recommended)
- Access keys are rotated regularly (every 90 days)
- CloudTrail logging is enabled for audit trail

❌ **Not recommended** if:
- You need strict least-privilege compliance
- Multiple teams share the same AWS account
- Regulatory requirements prohibit admin access for automation

## Alternative: Least-Privilege Policy

If you need stricter permissions, you can create a project-specific policy. Here's an example for this email forwarding project:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Route53Permissions",
      "Effect": "Allow",
      "Action": [
        "route53:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SESPermissions",
      "Effect": "Allow",
      "Action": [
        "ses:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Permissions",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::ses-email-forwarder-*",
        "arn:aws:s3:::ses-email-forwarder-*/*",
        "arn:aws:s3:::terraform-state-*",
        "arn:aws:s3:::terraform-state-*/*"
      ]
    },
    {
      "Sid": "LambdaPermissions",
      "Effect": "Allow",
      "Action": [
        "lambda:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBPermissions",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock-*"
    },
    {
      "Sid": "STSPermissions",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

## Usage

1. **For general CI/CD use**: Attach AWS-managed AdministratorAccess policy (recommended)
2. **For strict compliance**: Create a custom policy with only required permissions
3. **For this project only**: Use the least-privilege example above

## See Also

- [SETUP.md](SETUP.md) - Complete GitLab CI/CD setup guide
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
