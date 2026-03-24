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

Create a secret for RustFS credentials

```sh
kubectl create secret generic currents-rustfs-user \
  --from-literal=RUSTFS_ACCESS_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32) \
  --from-literal=RUSTFS_SECRET_KEY=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

Install RustFS

```sh
helm install rustfs rustfs --repo https://charts.rustfs.com -f samples/rustfs-helm-config.yaml
```

Create the `currents` bucket

```sh
kubectl apply -f samples/rustfs-create-bucket-job.yaml
kubectl wait --for=condition=complete job/rustfs-create-bucket --timeout=60s
```

Create an ingress for RustFS

```sh
kubectl apply -f samples/local/rustfs-ingress.yaml
```

Note that you will need to add `rustfs.localhost` to your `/etc/hosts` file on the loopback

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

Create required secrets for authentication and internal API
```sh
kubectl create secret generic currents-better-auth --from-literal=secret=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 64)
kubectl create secret generic currents-api-internal-token --from-literal=token=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Create root user password secret (used for initial admin account)
```sh
kubectl create secret generic currents-root-user --from-literal=password=$(head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c 32)

# To retrieve the generated password:
kubectl get secret currents-root-user -o jsonpath='{.data.password}' | base64 -d
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