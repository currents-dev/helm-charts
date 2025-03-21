- Differs from helm default in that there isn't one main deployment, but several microservice 'components' that make up the chart
- If a template needs use the component name, the template should take a dict with context and component defined (a standard used by bitnami and many other charts)
- Include as many of the default helm settings, even if we don't need them quite yet, only remove ones that don't make sense before we have other parts working
- The default settings will often have to be moved to either .global or a component config. There should be minimal settings left in the root config scope


Good to install k9s for exploring the cluster
 Also kubetail is decent https://github.com/johanhaleby/kubetail


Create namespace (easier to cleanup resources in a custom namespace)

```sh
kubectl create namespace currents
kubectl ns currents
```


## Install a mongo DB

```sh
helm repo add mongodb https://mongodb.github.io/helm-charts
helm install community-operator mongodb/community-operator
```

Edit the password in `samples/mongodb-community-replicaset.yml`

```sh
kubectl apply -f samples/mongodb-community-replicaset.yml
```

## Setup ES

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

## Setup Object Storage

### Option: Setup Minio

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

## Install the Currents Helm chart

Add/update pull secret

```sh
kubectl create secret docker-registry currents-pull-secret \
  --save-config \
  --dry-run=client \
  --docker-server=513558712013.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password) \
  -o yaml | \
  kubectl apply -f -
```

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

Setup the Object storage secrets:

```sh
KEYID=youraccesskey
KEYSECRET=yourkeysecret
kubectl create secret generic currents-object-storage --from-literal=keyId=$KEYID --from-literal=keySecret=$KEYSECRET
```


```sh
cd charts/currents
helm dep up
helm upgrade --install  -f config.yaml test-currents .
```

Access the api via port forward

```sh
  # Find the actual service name using # kubectl get services
  kubectl port-forward service/test-currents-server 4000:4000
```

Access the director via additional port forward

```sh
  # Find the actual service name using # kubectl get services
  kubectl port-forward service/test-currents-director 1234:1234
```