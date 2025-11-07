# Quickstart: Installing Currents on EKS

The QuickStart for installing the Currents Helm Chart on EKS runs through the commands to get the Currents App setup. This includes installing dependencies like MongoDB, Elasticsearch, and Minio into your Kubernetes namespace.

## Accessing Currents Docker Images

Your EKS Nodes must have been given IAM permissions to pull images from Current's Private ECR repositories. [See how](./iam.md).

## Prerequisites

- Have an supported EKS cluster running
  * SSD based StorageClass
  * An ALB IngressClass setup
- The ability to register two new subdomains for Currents
  * The `app` is the endpoint for serving the web frontend and REST API endpoints.
  * The `director` is the endpoint the test reporters communicate with.
- TLS certificates for the Currents subdomains (can be a wildcard)
- Have access to the cluster via your local kubectl
- Have Helm installed locally
- *recommended*: An Object Storage bucket for Currents like S3 or Cloudflare

## Setup Namespace

Create a namespace: `currents` to contain the resources related to the Currents install.

```sh
kubectl create namespace currents
kubectl ns currents
```

## 3rd Party Dependencies

Currents depends on several third-party services that are not bundled with the Helm chart. You are responsible for allocating resources, installing, and maintaining these services.

See [Currents Service Dependencies](./dependencies.md).



## Install the Currents Helm chart

Configure and install the Currents Helm Chart once all the services are ready.

1. Create required secrets for JWT auth and internal api
   ```sh
   kubectl create secret generic currents-api-jwt-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   kubectl create secret generic currents-api-internal-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   ```

2. Create a config file for the Currents Helm Charts values

   Be sure to customize the following:
   - `global.ingressClassName`
   - `currents.domains`
   - `currents.email.from`
   - `currents.email.host`
   - `currents.objectStorage.endpoint`
   - `currents.objectStorage.bucket`
   - `director.ingress.annotations`
   - `director.ingress.hosts`
   - `server.ingress.annotations`
   - `server.ingress.hosts`

   Also see the full [Configuration Reference](../configuration.md)

   Here is the sample config file

   `currents-helm-config.yaml`
   ```yaml
   global:
     imagePullPolicy: IfNotPresent
     # Place the ingressClass name for your alb IngressClass here
     ingressClassName: alb-currents

   currents:
     domains:
       https: true
       # This is the domain you want to access the app via the webbrowser
       appHost: currents.eks.currents-sandbox.work
       # This is the domain used to reach the director, called from the test reporters
       recordApiHost: currents-record.eks.currents-sandbox.work
     email:
       smtp:
         # The domain in the from address needs to be one your SMTP server is authorized to send from
         from: "Currents Report <report@eks.example.com>"
         # Enter your SMTP host
         host: smtp.mailgun.org
         secretName: currents-email-smtp
     objectStorage:
       # Enter your storage provider endpoint
       endpoint: https://s3.us-east-1.amazonaws.com
       # Enter your bucket name
       bucket: currents-my-org-name
       # Enter your region
       region: us-east-1

       # AUTHENTICATION CONFIGURATION:
       # Option 1: For IAM role-based authentication (recommended for AWS)
       # If using IAM roles for S3 access, REMOVE the secretName line completely

       # Option 2: For secret key-based authentication
       # If using secret keys, you MUST create this secret before installation
       secretName: currents-storage-user

       # NOTE: Choose either IAM (remove secretName) OR secret-based authentication.
       # Do NOT leave secretName in your configuration if you haven't created the secret.

       # Option 3: For minio deployed in the same K8s namespace
       # Use the following settings instead if you setup Minio
       # secretName: currents-minio-user
       # secretIdKey: CONSOLE_ACCESS_KEY
       # secretAccessKey: CONSOLE_SECRET_KEY
       # Set the endpoint to your Minio Route
       # endpoint: https://storage.eks.example.com
       # internalEndpoint: https://minio
       # bucket: currents
       # pathStyle: true

     gitlab:
       state:
         secretName: currents-gitlab-key 
         secretKey: gitlab-key.pem 
     apiJwtToken:
       secretName: currents-api-jwt-token
     apiInternalToken:
       secretName: currents-api-internal-token
     mongoConnection:
       secretName: mongodb-currents-currents-user
       key: connectionString.standardSrv
     clickhouse:
       user:
         secretName: clickhouse-currents-pass
         secretPasswordKey: password
       tls:
         enabled: false
       host: clickhouse-clickhouse

   director:
     ingress:
       enabled: true
       annotations:
         # Set to 'internet-facing' to expose to the public
         alb.ingress.kubernetes.io/scheme: internal
         alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
         alb.ingress.kubernetes.io/group.name: currents
         # Set the ARN a resource managed by aws certificate manager, that matches the DNS host
         alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:"
         alb.ingress.kubernetes.io/target-type: ip
       hosts:
         # Set the Director DNS name, often called the RECORD API
         - host: "{{ .Values.currents.domains.recordApiHost }}"
           paths:
             - path: /
               pathType: Prefix
   server:
     ingress:
       enabled: true
       annotations:
         # Set to 'internet-facing' to expose to the public
         alb.ingress.kubernetes.io/scheme: internal
         alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
         alb.ingress.kubernetes.io/group.name: currents
         # Set the ARN a resource managed by aws certificate manager, that matches the DNS host
         alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:"
         alb.ingress.kubernetes.io/target-type: ip
       hosts:
         # Set the server DNS name, often called APP
         - host: "{{ .Values.currents.domains.appHost }}"
           paths:
             - path: /
               pathType: Prefix

   redis:
     enabled: true
   ```

   See the full available configuration values here: https://github.com/currents-dev/helm-charts/blob/main/charts/currents/values.yaml

3. Install the chart
   ```sh
   helm upgrade --install currents currents --repo https://currents-dev.github.io/helm-charts/ -f currents-helm-config.yaml 
   ```

## Configure Service Account Access

If you are using S3 Object Storage and plan to use IAM roles to grant the Pods access rather than a secret, now is the time to follow [Setting up IAM Roles for Accessing Object Storage](./iam.md#iam-resources-for-accessing-currents-docker-images)

## Configure DNS

The Helm install step will have created a new load balancer which you can find in your ec2/LoadBalancers from the AWS console. 

Configure your DNS to point the domains we used for Currents at the newly created balancer.


## Use Currents

After following all the above steps, you should now be able to access the Currents Dashboard on the DNS you attached to the `server`.

And you can have Currents Test reporters access the `director` DNS by setting the `CURRENTS_API_URL` when you call them.

For example:
```sh
CURRENTS_API_URL=https://currents-record.eks.example.com npx pwc --key <your-key> --project-id <your projectid>
```