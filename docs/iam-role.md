# 🔐 Configure Access to ECR Images Using an IAM Role

Follow these steps to configure access to private Amazon ECR repositories via IAM role:

### 1. ✅ Create an IAM Role with Required Permissions
Create an IAM role with the following policy attached:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": [
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/api/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/api",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/change-streams/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/change-streams",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/director/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/director",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/scheduler/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/scheduler",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/writer/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/writer",
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/webhook/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/webhook"
      ]
    }
  ]
}
```

### 2. 📩 Share Role ARN
Send the ARN of the created IAM role to the Currents engineer so they can allow it to assume permissions on their side.

### 3. 🔄 Assume the IAM Role (from your terminal)
Use the AWS CLI to assume the role provided by Currents. Run:


`aws sts assume-role --role-arn <ROLE_ARN> --role-session-name currents-access-session`

Make sure to export the temporary credentials received (AccessKeyId, SecretAccessKey, SessionToken) into your environment variables for the session.

### 4. 🧪 Verify Access to ECR
Run the following to log in to ECR and pull the image:

`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 513558712013.dkr.ecr.us-east-1.amazonaws.com`

`docker pull 513558712013.dkr.ecr.us-east-1.amazonaws.com/currents/on-prem/api:staging-aarch64`
