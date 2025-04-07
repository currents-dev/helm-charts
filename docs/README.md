# Currents Helm Chart Installation Guide

This guide provides step-by-step instructions to install the Currents Helm chart.

## References

- [Developer Guide](./developer-guide/README.md)
- [EKS Quickstart](./eks/quickstart.md)

## Prerequisites

1. **Kubernetes Cluster**: Ensure you have a running Kubernetes cluster.
2. **Helm**: Install Helm (v3 or later). Refer to the [Helm installation guide](https://helm.sh/docs/intro/install/).
3. **Namespace**: Create a namespace for the Currents application:
   ```sh
   kubectl create namespace currents
   kubectl ns currents
   ```

## Installation Steps

1. Add the Helm repository:
   ```sh
   helm repo add currents https://currents-dev.github.io/helm-charts
   helm repo update
   ```

2. Install the chart:
   ```sh
   helm upgrade --install  -f config.yaml currents currents/currents
   ```

## Uninstallation

To uninstall the Currents Helm chart, run:
```sh
helm uninstall currents --namespace currents
```

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Configuration

The following table lists the configurable parameters of the `currents` chart and their default values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullSecrets` | Secrets for pulling images from private registries | `[]` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `global.additionalLabels` | Additional labels for all resources | `{}` |
| `global.podAnnotations` | Annotations for pods | `{}` |
| `global.env` | Global environment variables | `[]` |
| `global.containerSecurityContext` | Security context for containers | See `values.yaml` |
| `global.securityContext` | Security context for pods | See `values.yaml` |
| `global.priorityClassName` | Priority class name for pods | `""` |
| `global.volumes` | Additional volumes for pods | `[]` |
| `global.volumeMounts` | Additional volume mounts for containers | `[]` |
| `global.nodeSelector` | Node selector for pods | `{kubernetes.io/os: linux}` |
| `global.tolerations` | Tolerations for pods | `[]` |
| `global.affinity` | Affinity rules for pods | `{}` |
| `currents.imageTag` | Image tag for Currents components | `staging-x86_64` |
| `currents.domains.https` | Weather to use https protocol for links to the domains | `true` |
| `currents.domains.appHost` | Base domain for the application | `"http://currents-app.localhost"` |
| `currents.domains.apiHost` | Base domain for the test reporter client api | `"http://currents-app.localhost"` |
| `currents.email.smtp` | SMTP configuration for email | See `values.yaml` |
| `currents.rootUser.email` | Email address for the root org user | `root@currents.local` |
| `currents.ingress.enabled` | Enable ingress for Currents | `false` |
| `currents.apiJwtToken` | JWT token configuration | See `values.yaml` |
| `currents.apiInternalToken` | Internal API token configuration | See `values.yaml` |
| `currents.redis.host` | Redis host | `"{{ .Release.Name }}-redis-master"` |
| `currents.elastic` | ElasticSearch configuration | See `values.yaml` |
| `currents.objectStorage` | Object storage configuration | See `values.yaml` |
| `currents.mongoConnection` | MongoDB connection configuration | `{}` |
| `currents.gitlab` | GitLab integration configuration | See `values.yaml` |
| `director` | Configuration for the Director component | See `values.yaml` |
| `server` | Configuration for the Server component | See `values.yaml` |
| `writer` | Configuration for the Writer component | See `values.yaml` |
| `scheduler` | Configuration for the Scheduler component | See `values.yaml` |
| `changestreams` | Configuration for the Change Streams component | See `values.yaml` |
| `webhooks` | Configuration for the Webhooks component | See `values.yaml` |
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.name` | Name of the service account | `""` |
| `redis.enabled` | Enable Redis | `false` |

For detailed descriptions of each parameter, refer to the `values.yaml` file in the chart.



