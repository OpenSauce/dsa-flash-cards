---
title: "Security and IAM"
order: 4
summary: "IAM users, groups, roles, and policies. Principle of least privilege. Policy documents (Effect/Action/Resource). Roles vs access keys. How IAM connects to every AWS service."
---

## Why This Matters

Every action in AWS -- launching an instance, reading an S3 bucket, invoking a Lambda function -- goes through IAM authorization. Misunderstanding IAM leads to two failure modes: overly permissive access that creates security vulnerabilities, and overly restrictive access that breaks your application. IAM is the access control layer for the entire AWS cloud.

## IAM Concepts

IAM (Identity and Access Management) answers three questions: **who** is making a request, **what** action they want to perform, and **which resource** they want to act on.

### Users

An **IAM user** is a long-term identity representing a human (or, historically, a service). Users have credentials: a username/password for the AWS Console, and optionally access key ID + secret key for programmatic access.

Users are appropriate for human operators who log into the console. For services and applications accessing AWS programmatically, use roles instead.

### Groups

An **IAM group** is a collection of users. Policies attached to a group apply to all users in it. Groups do not have credentials -- they are purely a way to apply the same permissions to multiple users without duplicating policy attachments.

Example: a `Developers` group with read access to production resources and full access to dev/staging environments.

### Roles

An **IAM role** is a temporary identity that can be assumed by AWS services, applications, or users from another account. Roles do not have long-term credentials. When a role is assumed, AWS issues short-lived temporary credentials (STS tokens) that expire automatically.

**Why roles matter**: A Lambda function reading from S3 doesn't have a username or password. Instead, you attach an IAM role to the function. When the function runs, it assumes that role and gets temporary credentials with the permissions defined in the role's policy.

This is the fundamental pattern for service-to-service access in AWS: no hardcoded credentials, no rotation burden, no credential leakage.

### Policies

An **IAM policy** is a JSON document that defines what actions are allowed or denied on which resources. Policies are attached to users, groups, or roles.

A minimal policy document:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

Each statement has three required fields:
- **Effect**: `Allow` or `Deny`
- **Action**: One or more AWS API actions (e.g., `s3:GetObject`, `ec2:DescribeInstances`, `dynamodb:*`)
- **Resource**: The ARN(s) of the specific resources the statement applies to, or `*` for all

## Principle of Least Privilege

The principle of least privilege states: grant only the minimum permissions required to perform a task, and no more.

In practice:
- A Lambda function that reads from one S3 bucket should have `s3:GetObject` on that specific bucket ARN -- not `s3:*` on `*`.
- A CI/CD pipeline that deploys ECS tasks should have permissions to update ECS task definitions and start tasks -- not full EC2 and IAM admin access.

The common failure mode: using `"Action": "*", "Resource": "*"` during development because it's easy, then forgetting to tighten it before production. A single compromised service with admin-level IAM can result in a full account breach.

## Policy Evaluation Logic

When multiple policies apply to a request, AWS evaluates them in order:

1. **Explicit Deny**: If any policy contains an explicit `"Effect": "Deny"` matching the action/resource, the request is denied immediately. No allow overrides an explicit deny.
2. **Explicit Allow**: If no deny applies, but at least one policy contains an `"Effect": "Allow"`, the request is allowed.
3. **Implicit Deny**: If no allow applies, the request is denied by default.

This "deny wins" rule is important: you can use explicit denies in SCPs (Service Control Policies) to block actions across an entire organization, even if individual accounts have permissive policies.

## Roles vs Access Keys

Two ways for applications to authenticate with AWS:

**Access keys (IAM user credentials)**: A static access key ID and secret. Long-lived, don't expire unless manually rotated, must be stored securely. If leaked, an attacker has permanent access until the key is deactivated.

**IAM roles**: Short-lived temporary credentials issued by STS. Expire automatically (usually after 1 hour). Cannot be leaked in the traditional sense -- by the time an attacker could use stolen credentials, they may have already expired.

Roles are always preferred for anything running in AWS:
- EC2 instances: attach an instance profile (a role for EC2)
- Lambda functions: attach an execution role
- ECS tasks: attach a task role
- Cross-account access: assume a role in the target account

Access keys are used only for external systems (a GitHub Actions pipeline, a developer's local machine) that cannot assume a role because they aren't running in AWS. Even here, AWS offers OIDC-based role assumption for common CI/CD platforms, further reducing reliance on static access keys.

## Key Takeaways

- IAM controls who can do what on which AWS resources.
- Users are for humans. Groups organize users. Roles are for services and applications.
- A policy document has Effect (Allow/Deny), Action (API calls), and Resource (ARN). Explicit deny wins over any allow.
- The principle of least privilege: grant minimum permissions needed, scoped to specific resources.
- Roles issue temporary credentials automatically. Access keys are static and must be manually rotated -- prefer roles for all workloads running inside AWS.
