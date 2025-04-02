# Quickstart for EKS

The QuickStart steps for installing the Currents Helm Chart on EKS quickly runs through the commands to get a demo app setup. This includes installing MongoDB, Elasticsearch, and Minio into your Kubernetes namespace well. See the full Chart documentation for alternative configuration options for these services.

## Setup Namespace

Create namespace (easier to cleanup resources in a custom namespace)

```sh
kubectl create namespace currents
kubectl ns currents
```

## Setup prerequisites

<details>
<summary>MongoDB</summary>

```sh
helm repo add mongodb https://mongodb.github.io/helm-charts
helm install community-operator mongodb/community-operator
```

Edit the password in `samples/mongodb-community-replicaset.yml`

```sh
kubectl apply -f samples/mongodb-community-replicaset.yml
```

</details>

<details>
<summary>Elasticsearch</summary>

Advanced options avail at:
(docs: https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-install-helm.html )


```sh
helm repo add elastic https://helm.elastic.co
helm install elastic-operator-crds elastic/eck-operator-crds
helm install elastic-operator elastic/eck-operator  \
  --set=installCRDs=false \
  --set=managedNamespaces='{currents}' \
  --set=createClusterScopedResources=false \
  --set=webhook.enabled=false \
  --set=config.validateStorageClass=false
```

Install sample es cluster (docs: https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-elasticsearch.html )

```sh
kubectl apply -f samples/elasticsearch.yml
```

Wait for es to be available, then generate an api key by:

```sh
PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
kubectl exec elasticsearch-es-default-0 -- curl -u "elastic:$PASSWORD" -X POST -H "Content-Type: application/json" -d "{ \"name\": \"currents-key\" }"  "http://elasticsearch-es-http:9200/_security/api_key" > es-api.key.json
```

Create a new secret with the api info from the key we just created (requires jq installed locally)

```sh
kubectl create secret generic currents-es-api-key --from-literal=apiId=$(jq -r .id es-api.key.json) --from-literal=apiKey=$(jq -r .api_key es-api.key.json)
```

</details>

<details>
<summary>Object Storage</summary>

Add the minio operator

```sh
helm repo add minio https://operator.min.io/
helm install minio-operator minio/operator \
  --set operator.env\[0\].name=WATCHED_NAMESPACE \
  --set operator.env\[0\].value=currents \
  --set operator.replicaCount=1
```

Create the root user config (edit the username/password in samples/minio-config.env)

```sh
kubectl create secret generic currents-minio-env-configuration --from-file=config.env=samples/minio-config.env
```

Create the additional users for currents

```sh
kubectl create secret generic currents-minio-user --from-literal=CONSOLE_ACCESS_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | LC_ALL=C tr -dc 'a-zA-Z0-9'  | head -c 32) --from-literal=CONSOLE_SECRET_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

Create a minio tenant instance

```sh
helm install tenant minio/tenant -f samples/minio-tenant-helm-config.yaml
```

Create the EKS ALB ingress for Minio

Edit `samples/eks/minio-eks-ingress.yaml` to use your hostname for storage in the `hosts` section. And a valid certificate-arn in the annotations.

Then apply the ingress.

```sh
kubectl apply -f samples/eks/minio-eks-ingress.yaml
```

</details>

## Install the Currents Helm chart

Create JWT secret

```sh
kubectl create secret generic currents-api-jwt-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

Create internal API secret

```sh
kubectl create secret generic currents-api-internal-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

Create a GitLab private encoding key

```sh
openssl genrsa -out gitlab-key.pem 2048
kubectl create secret generic currents-gitlab-key --from-file=gitlab-key.pem
```

Edit your config file

`samples/eks/eks-config.yaml`

Setting the URLs to match your domains, and assigning your certificates.


Install the chart


```sh
helm upgrade --install  -f samples/eks/eks-config.yaml test-currents currents/currents
```