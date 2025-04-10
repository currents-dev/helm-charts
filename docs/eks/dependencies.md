# Currents Service Dependencies

Currents depends on several third-party services that are not bundled with the Helm chart. You are responsible for allocating resources, installing, and maintaining these services. During the installation process, you’ll need to provide credentials so Currents can configure these services as needed.

We provide a quick reference of how to create those services for your convenience.

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


### Elasticsearch

Advanced options are available at:
(docs: https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-elasticsearch.html )

This will setup a 1-node Elasticsearch cluster, requireing 2Gb of memory and using 5Gb of storage.

1. Install the Elasticsearch Operator
   ```sh
   helm install elastic-operator-crds eck-operator-crds --repo https://helm.elastic.co
   helm install elastic-operator eck-operator  \
     --repo https://helm.elastic.co \
     --set=installCRDs=false \
     --set=managedNamespaces='{currents}' \
     --set=createClusterScopedResources=false \
     --set=webhook.enabled=false \
     --set=config.validateStorageClass=false
   ```

2. Create the Elasticsearch Resources file to apply.

   `elasticsearch.yaml`
   ```yaml
   apiVersion: elasticsearch.k8s.elastic.co/v1
   kind: Elasticsearch
   metadata:
     name: elasticsearch
   spec:
     version: 8.17.3
     volumeClaimDeletePolicy: DeleteOnScaledownOnly
     nodeSets:
     - name: default
       count: 1
       config:
         node.store.allow_mmap: false
       volumeClaimTemplates:
       - metadata:
           name: elasticsearch-data # Do not change this name unless you set up a volume mount for the data path.
         spec:
           accessModes:
           - ReadWriteOnce
           resources:
             requests:
               storage: 5Gi
     http:
       tls:
         selfSignedCertificate:
           disabled: true
   ```

4. Apply the Elasticsearch Resource
   ```sh
   kubectl apply -f elasticsearch.yaml
   ```

5. Wait for the Elasticsearch pod to be available, then generate an api key:
   <!-- {% raw %} -->
   ```sh
   PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
   kubectl exec elasticsearch-es-default-0 -- curl -u "elastic:$PASSWORD" -X POST -H "Content-Type: application/json" -d "{ \"name\": \"currents-key\" }"  "http://elasticsearch-es-http:9200/_security/api_key" > es-api.key.json
   ```
   <!-- {% endraw %} -->

6. Create a new secret with the api info from the key we just created (requires jq installed locally)
   ```sh
   kubectl create secret generic currents-es-api-key --from-literal=apiId=$(jq -r .id es-api.key.json) --from-literal=apiKey=$(jq -r .api_key es-api.key.json)
   ```

### Object Storage (provider)

Follow this step if you plan to use provider (S3, Cloudflare) object storage (recommended).

1. Create a secret containing the access key and secret for the bucket you want to use for Currents 
   ```sh
   AWS_ACCESS_KEY_ID=<replace-with-access-key-id>
   AWS_SECRET_ACCESS_KEY=<replace-with-secret-access-key>
   kubectl create secret generic currents-storage-user --from-literal=apiId=$AWS_ACCESS_KEY_ID --from-literal=keySecret=$AWS_SECRET_ACCESS_KEY
   ```

2. You will configure the Currents Helm chart to use `currents-storage-user` and your Object Storage bucket later in these instructions.

### Alternative Object Storage (in cluster)

Install Minio if you don't have access to an Object Storage provider (S3, Cloudflare). You will need an additional subdomain for Minio.

Creates a single Pod instance of Minio with 10Gb of storage.

1. Add the minio operator
   ```sh
   helm install minio-operator operator \
     --repo https://operator.min.io/
     --set operator.env\[0\].name=WATCHED_NAMESPACE \
     --set operator.env\[0\].value=currents \
     --set operator.replicaCount=1
   ```

2. Create the root user config environment
   ```sh
   printf 'export MINIO_ROOT_USER="%s"\nexport MINIO_ROOT_PASSWORD="%s"\n' $(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | LC_ALL=C tr -dc 'a-zA-Z0-[B9'  | head -c 32) $(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32) > minio-config.env
   kubectl create secret generic currents-minio-env-configuration --from-file=config.env=minio-config.env
   ```

3. Create the additional users for currents
   ```sh
   kubectl create secret generic currents-minio-user --from-literal=CONSOLE_ACCESS_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | LC_ALL=C tr -dc 'a-zA-Z0-9'  | head -c 32) --from-literal=CONSOLE_SECRET_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
   ```

4. Create a Minio Tenant Values file

   `minio-tenant-helm-config.yaml`
   ```yaml
   tenant:
     name: currents-minio
     configuration:
       name: currents-minio-env-configuration
     configSecret:
       existingSecret: true
       accessKey: null
       secretKey: null
     pools:
       - servers: 1
         name: pool-0
         volumesPerServer: 1
         size: 10Gi
         storageAnnotations: { }
         storageLabels: { }
         annotations: { }
         labels: { }
         tolerations: [ ]
         nodeSelector: { }
         affinity: { }
         resources: { }
         securityContext:
           runAsUser: 1000
           runAsGroup: 1000
           fsGroup: 1000
           fsGroupChangePolicy: "OnRootMismatch"
           runAsNonRoot: true
         containerSecurityContext:
           runAsUser: 1000
           runAsGroup: 1000
           runAsNonRoot: true
           allowPrivilegeEscalation: false
           capabilities:
             drop:
               - ALL
           seccompProfile:
             type: RuntimeDefault
         topologySpreadConstraints: [ ]
     buckets:
       - name: currents
     users:
       - name: currents-minio-user
   ```

5. Install the Minio Tenant Instance
   ```sh
   helm install minio-tenant tenant --repo https://operator.min.io/  -f minio-tenant-helm-config.yaml
   ```

6. Create an Ingress Resource to expose the Minio S3 api

   Be sure to customize the following:
   - `alb.ingress.kubernetes.io/certificate-arn`
   - `spec.ingressClassName`
   - `spec.rules.host`

   file: `minio-eks-ingress.yaml`
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ingress-minio
     annotations:
       # Set to 'internet-facing' to expose to the public
       alb.ingress.kubernetes.io/scheme: internal
       alb.ingress.kubernetes.io/group.name: currents
       # Set the ARN a resource managed by aws certificate manager, that matches the DNS host
       alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:"
       alb.ingress.kubernetes.io/target-type: ip
       alb.ingress.kubernetes.io/backend-protocol: HTTPS
       alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
       alb.ingress.kubernetes.io/success-codes: '200,403'
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
                   name: minio
                   port:
                     number: 443
   ```

7. Apply the Ingress file
   ```sh
   kubectl apply -f minio-eks-ingress.yaml
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
