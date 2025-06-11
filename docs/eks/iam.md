# IAM Resources

## IAM Resources for Accessing Currents Docker Images

Currents Docker images are hosted in a private ECR registry. To gain access, follow these steps:

### 1. ✅ Create an IAM Role with Required Permissions
Create an IAM role with the following policy attached:

```json
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
        "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/webhooks/*",
        "arn:aws:ecr:us-east-1:513558712013:repository/currents/on-prem/webhooks"
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

## Using IAM Roles for Accessing Object Storage

### IRSA

When deployed in EKS and using S3 for storage, you can use [IAM roles for service accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) to access your S3 bucket.

Prerequisites:

- An EKS cluster with an [IAM OIDC Provider enabled](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html).
- An S3 bucket created for use with Currents Object Storage. Ensure the bucket name is unique and follows AWS naming conventions.

Steps:

**1. Create the IAM Policy**

This policy allows the Currents service account to perform actions such as listing and accessing objects in the specified S3 bucket. Replace the two instances of `my-currents-bucket` in the policy below with the name of your bucket.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*Object",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::my-currents-bucket/*",
                "arn:aws:s3:::my-currents-bucket"
            ]
        }
    ]
}
```

After creating the policy, copy its ARN for use in later commands.

**2. Find the Existing Currents Service Account**

If you haven't already installed the Currents Helm Chart, [complete those steps first](./quickstart.md), then return here to set up the IAM roles.

Locate the name of your Currents service account. It should match the name of the Helm Chart installation for Currents, usually `currents`.

```shell
kubectl get sa
```

Example output:

```shell
NAME                          SECRETS   AGE
currents                      0         5m29s
currents-redis-master         0         5m29s
default                       0         25m
elastic-operator              0         17m
mongodb-database              0         25m
mongodb-kubernetes-operator   0         25m
```

**3. Create and Attach the IAM Role**

It is recommended to use `eksctl` to create the role. Alternatively, you can follow the [AWS instructions for using the AWS CLI](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html#_step_2_create_and_associate_iam_role).

Run the following command, updating `--name currents` with the Currents service account name. Replace `<your-cluster-name>` with the name of your EKS cluster and `<your-policy-arn>` with the ARN of the IAM policy you created earlier.

```shell
eksctl create iamserviceaccount --name currents --namespace currents --cluster <your-cluster-name> --role-name currents-irsa \
  --attach-policy-arn <your-policy-arn> --override-existing-serviceaccounts --approve
```

**4. Confirm the Currents Service Account Has the Role**

Run the following command to describe the service account:

```shell
kubectl describe serviceaccount currents
```

Expected Output:
The `eks.amazonaws.com/role-arn` annotation should appear in the service account description:

```
Annotations:  eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/currents-irsa
```

**5. Restart the Pods to Apply the New IAM Role**

Restarting the pods ensures they pick up the new IAM role. Run the following command:

```shell
kubectl delete pods -l app.kubernetes.io/name=currents
```

After the pods restart, describe one of the Currents pods to confirm the `AWS_WEB_IDENTITY_TOKEN_FILE` environment variable is set:

```shell
kubectl describe pod <pod-name>
```
