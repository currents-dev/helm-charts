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

## Using IAM Roles for Sending Email with SES

By default Currents sends outgoing email (invitations, automated reports) over SMTP,
which requires storing SMTP credentials in a Kubernetes secret. If you'd rather not
hold those credentials in the cluster, Currents can send through
[Amazon SES](https://docs.aws.amazon.com/ses/latest/dg/Welcome.html) instead and
authenticate with an IAM role — no email secret required.

Prerequisites:

- An EKS cluster with an [IAM OIDC Provider enabled](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) (same requirement as IRSA for object storage, above).
- A **verified identity** in SES — the domain or address you send from — in the region you plan to use.
- If your SES account is still in the [sandbox](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html), every recipient must also be verified. Request production access before relying on this for real reports.

**1. Create the IAM Policy**

Replace `us-east-1`, `111122223333`, and the identity name with your own. Scoping to
the identity is optional but recommended; `"Resource": "*"` also works.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "arn:aws:ses:us-east-1:111122223333:identity/example.com"
        }
    ]
}
```

**2. Attach the Policy to the Currents Service Account**

Currents uses a single service account for all of its pods, so if you already set up
IRSA for object storage you can attach this policy to that same role rather than
creating a second one:

```shell
aws iam attach-role-policy --role-name currents-irsa --policy-arn <your-policy-arn>
```

If you have not set up IRSA yet, follow steps 2–4 of
[Using IAM Roles for Accessing Object Storage](#using-iam-roles-for-accessing-object-storage)
to create and associate the role, attaching this policy instead of (or in addition
to) the S3 one.

**3. Switch the Chart to the SES Transport**

In your `currents-helm-config.yaml`:

```yaml
currents:
  email:
    transporter: ses
    # Must be a verified SES identity in the region below
    from: "Currents Report <report@example.com>"
    ses:
      region: us-east-1
```

With `transporter: ses` the SMTP settings are ignored — `currents.email.smtp.host`
and `currents.email.smtp.secretName` are no longer required, and you do not need to
create the `currents-email-smtp` secret. The other email settings
(`inviteFrom`, `inviteBcc`, `reportsBcc`, `inviteExpirationDays`, `linksBaseUrl`)
apply to both transports.

Apply it:

```shell
helm upgrade --install currents currents --repo https://currents-dev.github.io/helm-charts/ -f currents-helm-config.yaml
```

**4. Confirm the Pods Picked Up the Change**

Email is sent by the `server` pod (invitations) and the `writer` pod (automated
reports). Confirm both see the SES settings and the IRSA credentials:

```shell
kubectl exec deploy/currents-writer -- env | grep -E 'EMAIL_TRANSPORTER|SES_REGION|AWS_ROLE_ARN|AWS_WEB_IDENTITY_TOKEN_FILE'
```

Expected output:

```
EMAIL_TRANSPORTER=ses
SES_REGION=us-east-1
AWS_ROLE_ARN=arn:aws:iam::111122223333:role/currents-irsa
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

If `EMAIL_TRANSPORTER` is still `smtp`, the values did not reach the pod — re-run the
upgrade with your full values file rather than `--reuse-values`, and confirm the
deployment rolled.

**5. Verify Delivery**

Trigger an email (for example, invite a user) and check the logs:

```shell
kubectl logs deploy/currents-writer --tail=100 | grep -i email
```

> **Note:** a successful send logs `Message sent`. Delivery failures are logged as
> `Error sending email with SES` — but they are **followed by a misleading
> `Email sent` line**, so treat the presence of an `Error sending email with SES`
> entry as a failure regardless of what comes after it. Common causes are an
> unverified `from` identity, a region mismatch, or SES sandbox restrictions on the
> recipient.
