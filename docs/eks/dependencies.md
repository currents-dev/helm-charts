# Currents Service Dependencies

Currents depends on several third-party services that are not bundled with the Helm chart. You are responsible for allocating resources, installing, and maintaining these services. During the installation process, you’ll need to provide credentials so Currents can configure these services as needed.

We provide a quick reference of how to create those services for your convenience. The documented configuration for the connected stateful services (mongo, clickhouse) are not definitive, and may not be adequate for all production setups.

### MongoDB

This will setup a 2-node Mongo Cluster, with each being 10Gb available for storage size.

1. Install the MongoDB Community Operator
   ```sh
   helm install community-operator community-operator --repo https://mongodb.github.io/helm-charts
   ```

2. Create Secrets for the MongoDB instances
   ```sh
   kubectl create secret generic mongo-admin-password --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   kubectl create secret generic mongo-currents-password --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   ```

3. Create the MongoDB Databases Resources file to apply

   `mongodb-community-resources.yaml`
   ```yaml
   apiVersion: mongodbcommunity.mongodb.com/v1
   kind: MongoDBCommunity
   metadata:
     name: mongodb
   spec:
     members: 2
     type: ReplicaSet
     version: "7.0.17"
     security:
       authentication:
         modes: ["SCRAM"]
     users:
       - name: cluster-admin
         db: admin
         passwordSecretRef: # a reference to the secret that will be used to generate the user's password
           name: mongo-admin-password
         roles:
           - name: clusterAdmin
             db: admin
           - name: userAdminAnyDatabase
             db: admin
           - name: dbAdminAnyDatabase
             db: admin
         scramCredentialsSecretName: admin-scram
       - name: currents-user
         db: currents
         passwordSecretRef: # a reference to the secret that will be used to generate the user's password
           name: mongo-currents-password
         roles:
           - name: dbOwner
             db: currents
         scramCredentialsSecretName: currents-scram
     additionalMongodConfig:
       storage.wiredTiger.engineConfig.journalCompressor: zlib
   ```

4. Apply the MongoDBCommunity Resource to create the Database

   ```sh
   kubectl apply -f mongodb-community-resources.yaml
   ```


### ClickHouse

For ClickHouse there are several production support options:

- Sass Cloud instances (Via [ClickHouse Cloud](https://clickhouse.com/cloud) or [Altinity Cloud](https://docs.altinity.com/altinitycloud/))
- Bring your own Cloud ([install ClickHouse Cloud in your AWS](https://clickhouse.com/docs/cloud/reference/byoc/overview))
- On-Premises Kubernetes Deployments ([ClickHouse Private](https://clickhouse.com/docs/cloud/infrastructure/clickhouse-private) or [Altinity Operator](https://docs.altinity.com/altinitykubernetesoperator/))

For this guide we are going to install the open-source [Altinity Kubernetes Operator for ClickHouse](https://docs.altinity.com/altinitykubernetesoperator/)

Advanced configuration available at:
(docs: https://github.com/Altinity/helm-charts/blob/main/charts/clickhouse/README.md )

This will setup a 1-node 1-shard ClickHouse Replicated Server (10Gb Storage)


1. Create Secrets for the ClickHouse Users
   ```sh
    kubectl create secret generic clickhouse-default-pass --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
    kubectl create secret generic clickhouse-currents-pass --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   ```
2. Install the Altinity Kubernetes Operator
   ```sh
   helm install clickhouse-operator altinity-clickhouse-operator --repo https://docs.altinity.com/clickhouse-operator
   ```

3. Install the Altinity Kubernetes Operator
   ```sh
   helm install clickhouse clickhouse --repo https://helm.altinity.com \
     --set=clickhouse.defaultUser.password_secret_name=clickhouse-default-pass \
     --set-json='clickhouse.users=[{"name":"currents","password_secret_name":"clickhouse-currents-pass"}]' \
     --set operator.enabled=false
   ```

### Object Storage (provider)

Follow this step if you plan to use provider (S3, Cloudflare) object storage (recommended).

1. Ensure you have created an Object Storage bucket for Currents in your provider.

2. If using S3, you can choose to setup IAM permissions for the Currents service account. If so, you can skip the rest of these steps, and setup the IAM access after installing the Helm chart.

3. Create a secret containing the access key and secret for the bucket you want to use for Currents 
   ```sh
   AWS_ACCESS_KEY_ID=<replace-with-access-key-id>
   AWS_SECRET_ACCESS_KEY=<replace-with-secret-access-key>
   kubectl create secret generic currents-storage-user --from-literal=apiId=$AWS_ACCESS_KEY_ID --from-literal=keySecret=$AWS_SECRET_ACCESS_KEY
   ```

4. You will configure the Currents Helm chart to use `currents-storage-user` and your Object Storage bucket later in these instructions.

### Alternative Object Storage (in cluster)

Install RustFS if you don't have access to an Object Storage provider (S3, Cloudflare). You will need an additional subdomain for RustFS.

Creates a single Pod instance of RustFS with 10Gi of storage.

1. Create a secret for RustFS credentials
   ```sh
   kubectl create secret generic currents-rustfs-user \
     --from-literal=RUSTFS_ACCESS_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32) \
     --from-literal=RUSTFS_SECRET_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   ```

2. Create a RustFS values file

   `rustfs-helm-config.yaml`
   ```yaml
   # Standalone mode for dev/test - single pod
   mode:
     standalone:
       enabled: true
     distributed:
       enabled: false

   # Use the secret we created for credentials
   secret:
     existingSecret: "currents-rustfs-user"

   # Service configuration
   service:
     type: ClusterIP
     endpoint:
       port: 9000
     console:
       port: 9001

   # Disable gateway API / TraefikService CRD creation
   gatewayApi:
     gatewayClass: ""

   # Disable built-in ingress (we create our own for full control)
   ingress:
     enabled: false

   # Storage configuration
   storageclass:
     name: ""  # Uses default storage class
     dataStorageSize: "10Gi"
     logStorageSize: "256Mi"

   # Resource limits
   resources:
     limits:
       cpu: "500m"
       memory: "512Mi"
     requests:
       cpu: "100m"
       memory: "128Mi"
   ```

3. Install RustFS
   ```sh
   helm install rustfs rustfs --repo https://charts.rustfs.com -f rustfs-helm-config.yaml
   ```

4. Create an Ingress Resource to expose the RustFS S3 API

   Be sure to customize the following:
   - `alb.ingress.kubernetes.io/certificate-arn`
   - `spec.ingressClassName`
   - `spec.rules[0].host`

   `rustfs-eks-ingress.yaml`
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ingress-rustfs
     annotations:
       # Set to 'internet-facing' to expose to the public
       alb.ingress.kubernetes.io/scheme: internal
       alb.ingress.kubernetes.io/group.name: currents
       # Set the ARN to a resource managed by AWS Certificate Manager
       alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:"
       alb.ingress.kubernetes.io/target-type: ip
       alb.ingress.kubernetes.io/backend-protocol: HTTP
       alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
       alb.ingress.kubernetes.io/healthcheck-path: /health
       alb.ingress.kubernetes.io/success-codes: '200'
   spec:
     ingressClassName: alb-currents
     rules:
       # Set the storage DNS name
       - host: storage.eks.example.com
         http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: rustfs
                   port:
                     number: 9000
   ```

   ```sh
   kubectl apply -f rustfs-eks-ingress.yaml
   ```

5. Create the `currents` bucket by applying a Job that uses mc (MinIO client)

   `rustfs-create-bucket-job.yaml`
   ```yaml
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: rustfs-create-bucket
   spec:
     ttlSecondsAfterFinished: 300
     template:
       spec:
         restartPolicy: Never
         containers:
           - name: mc
             image: minio/mc:latest
             env:
               - name: RUSTFS_ACCESS_KEY
                 valueFrom:
                   secretKeyRef:
                     name: currents-rustfs-user
                     key: RUSTFS_ACCESS_KEY
               - name: RUSTFS_SECRET_KEY
                 valueFrom:
                   secretKeyRef:
                     name: currents-rustfs-user
                     key: RUSTFS_SECRET_KEY
             command:
               - /bin/sh
               - -c
               - |
                 mc alias set rustfs http://rustfs-svc:9000 $RUSTFS_ACCESS_KEY $RUSTFS_SECRET_KEY
                 mc mb --ignore-existing rustfs/currents
   ```

   ```sh
   kubectl apply -f rustfs-create-bucket-job.yaml
   kubectl wait --for=condition=complete job/rustfs-create-bucket --timeout=60s
   ```

### SMTP Email

For sending outgoing emails like Automated reports. 

1. Create a secret that contains the smtp username/password
   ```sh
   SMTP_USERNAME=<replace-with-smtp-username>
   SMTP_PASSWORD=<replace-with-smtp-password>
   kubectl create secret generic currents-email-smtp --from-literal=username=$SMTP_USERNAME  --from-literal=password=$SMTP_PASSWORD
   ```

2. You will configure the Currents Helm chart to use `currents-email-smtp` and your SMTP host later in these instructions.

### GitLab

1. Create a private key for encoding communication between GitLab and Currents
   ```sh
   openssl genrsa -out gitlab-key.pem 2048
   kubectl create secret generic currents-gitlab-key --from-file=gitlab-key.pem
   ```

2. You will configure the Currents Helm chart to use `currents-gitlab-key` later in these instructions.
