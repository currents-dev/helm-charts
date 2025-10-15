# Install for local development

## Setup Namespace

Create namespace (easier to cleanup resources in a custom namespace)

```sh
kubectl create namespace currents
kubectl ns currents
```


## Setup prerequisites

<details>
<summary>Ingress</summary>

Install nginx ingress

```sh
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --set controller.scope.enabled=true \
  --set controller.allowSnippetAnnotations=true \
  --set controller.config.annotations-risk-level=Critical \
  --set controller.ingressClass=currents-nginx \
  --set controller.ingressClassResource.name=currents-nginx
```

</details>

<details>
<summary>MongoDB</summary>

```sh
helm install community-operator community-operator --repo https://mongodb.github.io/helm-charts
```

Edit the password in `samples/mongodb-community-replicaset.yml`

```sh
kubectl apply -f samples/mongodb-community-replicaset.yml
```

</details>

<details>
<summary>Clickhouse</summary>

Create a secrets for user passwords

```sh
kubectl create secret generic clickhouse-default-pass --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
kubectl create secret generic clickhouse-currents-pass --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

```sh
helm install clickhouse clickhouse --repo https://helm.altinity.com \
    --set=clickhouse.defaultUser.password_secret_name=clickhouse-default-pass \
    --set-json='clickhouse.users=[{"name":"currents","password_secret_name":"clickhouse-currents-pass"}]'
```
</details>

<details>
<summary>Object Storage</summary>

Add the minio operator

```sh
helm install minio-operator operator \
  --repo https://operator.min.io/ \
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
helm install tenant tenant --repo https://operator.min.io/ -f samples/minio-tenant-helm-config.yaml
```

Create an ingress for minio

```sh
kubectl apply -f samples/local/minio-ingress.yaml
```

Note that you will need to add `mino.localhost` to your `/etc/hosts` file on the loopback

</details>

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

Create required secrets for JWT auth and internal api
```sh
kubectl create secret generic currents-api-jwt-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
kubectl create secret generic currents-api-internal-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

Create a GitLab private encoding key

```sh
openssl genrsa -out gitlab-key.pem 2048
kubectl create secret generic currents-gitlab-key --from-file=gitlab-key.pem
```

Install the chart


```sh
(cd charts/currents && helm dep up)
helm upgrade --install  -f samples/local/chart-config.yaml test-currents ./charts/currents
```

Expose the ingress controller to access all the apis
Needs to use sudo to get port 80

```sh
sudo kubectl port-forward service/ingress-nginx-controller 80:80
```