- Differs from helm default in that there isn't one main deployment, but several microservice 'components' that make up the chart
- If a template needs use the component name, the template should take a dict with context and component defined (a standard used by bitnami and many other charts)
- Include as many of the default helm settings, even if we don't need them quite yet, only remove ones that don't make sense before we have other parts working
- The default settings will often have to be moved to either .global or a component config. There should be minimal settings left in the root config scope


Good to install k9s for exploring the cluster


Create namespace (easier to cleanup resources in a custom namespace)

```sh
kubectl create namespace deej-mar7
kubectl config set-context --current --namespace deej-mar7
```


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
kubectl create secret generic currents-api-jwt-token --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
```


Install a mongo DB

```
helm repo add mongodb https://mongodb.github.io/helm-charts
helm install community-operator mongodb/community-operator
```

Edit the password in `samples/mongodb-community-replicaset.yml`

```
kubectl apply -f samples/mongodb-community-replicaset.yml
```


Access the api via port forward

```
kubectl port-forward service/deej-test-currents-server 4000:4000
```