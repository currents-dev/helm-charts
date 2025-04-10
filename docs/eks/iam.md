# IAM Resources For Accessing Currents Docker Images

Currents Docker images are hosted in a private ECR registry. To have access follow the steps:

- create an IAM role with a policy that grants **ECR pull permissions** (see below)
- send Currents team your AWS ARN


## Reference Policy

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
				  "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/change-streams/*",
				  "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/director/*",
				  "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/scheduler/*",
				  "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/writer/*"
				  "arn:aws:ecr:us-east-1:513558712013:currents/on-prem/webhooks/*"
			  ]
		  
	]
}
```

