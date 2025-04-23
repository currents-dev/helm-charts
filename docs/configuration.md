# Configuration Reference

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2025-04-23-001](https://img.shields.io/badge/AppVersion-2025--04--23--001-informational?style=flat-square)

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | redis | 20.2.1 |

The following table lists the configurable parameters of the `currents` chart and their default values:

## Values

### Required

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| currents.domains.appHost | string | `"currents-app.localhost"` | The host for the app |
| currents.domains.recordApiHost | string | `"currents-record.localhost"` | The host for the recording endpoint that the test reporters communicate with |
| currents.email.smtp.host | string | `""` | the SMTP server to use |
| currents.email.smtp.secretName | string | `""` | K8s secret to use for the SMTP username/password |
| currents.apiJwtToken.secretName | string | `""` | The K8s secret to use for the JWT token |
| currents.apiInternalToken.secretName | string | `""` | The K8s secret to use for the internal API token |
| currents.elastic.admin.secretName | string | `""` | The k8s secret to use for the admin password |
| currents.elastic.admin.secretKey | string | `""` | The k8s secret key to use for the admin password |
| currents.elastic.apiUser.secretName | string | `""` | The k8s secret to use for the elasticsearch api key |
| currents.elastic.host | string | `""` | The elasticsearch host to use |
| currents.objectStorage.endpoint | string | `""` | The object storage endpoint to use |
| currents.objectStorage.secretName | string | `""` | The K8s secret to use for the object storage access key |
| currents.objectStorage.bucket | string | `""` | The object storage bucket to use |
| currents.mongoConnection.secretName | string | `""` | The K8s secret to use for the MongoDB connection string |
| currents.mongoConnection.key | string | `""` | The K8s secret key to use for the MongoDB connection string |
| currents.gitlab.state.secretName | string | `""` | The K8s secret to use for the GitLab state key |
| currents.gitlab.state.secretKey | string | `""` | The K8s secret key to use for the GitLab state key |
| redis.enabled | bool | `false` | enable the Bitnami Redis chart. Refer to https://github.com/bitnami/charts/blob/main/bitnami/redis/ for possible values. |

### Frequently Used

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| currents.domains.https | bool | `true` | Whether to use https or http |
| currents.email.smtp.secretUserKey | string | `"username"` | The K8s secret key to use for the SMTP username |
| currents.email.smtp.secretPasswordKey | string | `"password"` | The K8s secret key to use for the SMTP password |
| currents.apiJwtToken.key | string | `"token"` | The K8s secret key to use for the JWT token |
| currents.apiInternalToken.key | string | `"token"` | The K8s secret key to use for the internal API token |
| currents.elastic.admin.username | string | `"elastic"` | The elasticsearch admin username (used to manage the indexes) |
| currents.elastic.apiUser.idKey | string | `"apiId"` | The k8s secret key to use for the elasticsearch api ID |
| currents.elastic.apiUser.secretKey | string | `"apiKey"` | The k8s secret key to use for the elasticsearch api key |
| currents.elastic.tls.enabled | bool | `true` | Whether to use TLS for the elasticsearch connection |
| currents.objectStorage.secretIdKey | string | `"keyId"` | The K8s secret key to use for the object storage access key ID |
| currents.objectStorage.secretAccessKey | string | `"keySecret"` | The K8s secret key to use for the object storage secret access key |
| global.imagePullSecrets | list | `[]` | Reference to one or more secrets to be used when pulling images. [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). |
| director.resources | object | `{}` | Resources to provide [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| director.ingress.enabled | bool | `false` (but can also be turned on by currents.ingress.enabled) | Whether to enable the director ingress |
| director.ingress.className | string | `""` | The ingress class to use |
| director.ingress.annotations | object | `{}` | Annotations to add to the ingress |
| director.ingress.hosts | list | see [values.yaml] for default values | The hosts to use for the ingress |
| director.ingress.tls | list | see [values.yaml] for default values | The TLS configuration for the ingress |
| server.resources | object | `{}` | Resources to provide [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| server.ingress.enabled | bool | `false` (but can also be turned on by currents.ingress.enabled) | Whether to enable the server ingress |
| server.ingress.className | string | `""` | The ingress class to use |
| server.ingress.annotations | object | `{}` | Annotations to add to the ingress |
| server.ingress.hosts | list | see [values.yaml] for default values | The hosts to use for the ingress |
| server.ingress.tls | list | see [values.yaml] for default values | The TLS configuration for the ingress |
| writer.resources | object | `{}` (defaults to global.resources) | Resources to provide [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| scheduler.resources | object | `{}` (defaults to global.resources) | Resources to provide [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| changestreams.resources | object | `{}` (defaults to global.resources) | Resources to provide [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| webhooks.resources | object | `{}` (defaults to global.resources) | Resources to provide [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| currents.rootUser.email | string | `"admin@{{ .Values.currents.domains.appHost }}"` | The email address of the root user |
| currents.imageTag | string | `"2025-04-23-001"` | The image tag to use for the Currents images |
| currents.email.smtp.port | int | `587` | The SMTP server port to use |
| currents.email.smtp.from | tpl/string | `"Currents Report <report@{{ .Values.currents.domains.appHost }}>"` | The email address to send from |
| currents.email.smtp.tls | bool | `false` | Whether the SMTP server uses TLS |
| currents.ingress.enabled | bool | `false` | Whether to enable the both default ingresses (server, and director) |
| currents.apiJwtToken.expiry | string | `"1d"` | How often to expire session tokens signed by the JWT token |
| currents.redis.host | tpl | `{{ .Release.Name }}-redis-master` | set the redis hostname to talk to |
| currents.elastic.datastreams.instances | string | `"currents_dev_instances"` | The elasticsearch index to use for instances |
| currents.elastic.datastreams.tests | string | `"currents_dev_tests"` | The elasticsearch index to use for tests |
| currents.elastic.datastreams.runs | string | `"currents_dev_runs"` | The elasticsearch index to use for runs |
| currents.elastic.port | int | `9200` | The elasticsearch port to use |
| currents.objectStorage.internalEndpoint | string | `""` | The object storage internal endpoint to use (for internal communication) |
| currents.objectStorage.region | string | `""` | The region to use for the object storage |
| currents.objectStorage.pathStyle | bool | `false` | Whether to use path style access for the object storage |
| currents.logger.apiEndpoint | string | `""` | The coralogix API endpoint to use |
| currents.logger.apiSecretName | string | `""` | The k8s secret to use for the coralogix private key |
| currents.logger.apiSecretKey | string | `"apiKey"` | The k8s secret key to use for the coralogix private key |
| global.imagePullPolicy | string | `"IfNotPresent"` | The image pull policy to use for all images |
| global.additionalLabels | object | `{}` | Labels to apply to all resources. |
| global.podAnnotations | object | `{}` | This is for setting Kubernetes Annotations to a Pod |
| global.env | list | `[]` | Additional environment variables to pass to binary. |
| global.containerSecurityContext | dict | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Container Security Context to be set on the pods [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/). |
| global.securityContext | dict | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch","runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod Security Context. [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/). |
| global.revisionHistoryLimit | string | `nil` | The number of old ReplicaSets to retain to allow rollback (if not set, the default Kubernetes value is set to 10). |
| global.priorityClassName | string | `""` | The optional priority class to be used for the currents pods. |
| global.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| global.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| global.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | This default ensures that Pods are only scheduled to Linux nodes. It prevents Pods being scheduled to Windows nodes in a mixed OS cluster. |
| global.tolerations | list | `[]` |  |
| global.affinity | object | `{}` |  |
| director.name | string | `"director"` |  |
| director.replicas | int | `1` |  |
| director.image.registry | string | `"513558712013.dkr.ecr.us-east-1.amazonaws.com"` | The container registry to pull the manager image from. |
| director.image.repository | string | `"currents/on-prem/director"` | The container image for Currents Director. |
| director.image.tag | string | `""` | Override the image tag to deploy by setting this variable. |
| director.image.digest | string | `""` | Setting a digest will override any tag. |
| director.image.pullPolicy | string | `""` | default to the same as global.image.pullPolicy |
| director.deploymentStrategy | object | `{}` | Deployment update strategy for Currents deployment. [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy) |
| director.env | list | `[]` | Env variables to pass to the container |
| director.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| director.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| director.livenessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Liveness probe to check if the container is alive |
| director.readinessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Readiness probe to check if the container is ready |
| director.nodeSelector | object | `{}` (defaults to global.nodeSelector) | [Node selector] |
| director.tolerations | list | `[]` (defaults to global.tolerations) | [Tolerations] for use with node taints |
| director.affinity | object | `{}` (defaults to the global.affinity preset) | Assign custom [affinity] rules to the deployment |
| director.service | object | `{"port":1234,"type":"ClusterIP"}` | This is for setting up a service [more information](https://kubernetes.io/docs/concepts/services-networking/service/) |
| server.name | string | `"server"` |  |
| server.replicas | int | `1` |  |
| server.image.registry | string | `"513558712013.dkr.ecr.us-east-1.amazonaws.com"` | The container registry to pull the manager image from |
| server.image.repository | string | `"currents/on-prem/api"` | The container image for Currents Server API |
| server.image.tag | string | `""` | Override the image tag to deploy by setting this variable |
| server.image.digest | string | `""` | Setting a digest will override any tag |
| server.image.pullPolicy | string | `""` | defaults to global.image.pullPolicy |
| server.deploymentStrategy | object | `{}` | Deployment update strategy for Currents deployment |
| server.env | list | `[]` | Env variables to pass to the container |
| server.volumes | list | `[]` | Additional volumes on the output Deployment definition |
| server.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| server.livenessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Liveness probe to check if the container is alive |
| server.readinessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Readiness probe to check if the container is ready |
| server.nodeSelector | object | `{}` (defaults to global.nodeSelector) | [Node selector] |
| server.tolerations | list | `[]` (defaults to global.tolerations) | [Tolerations] for use with node taints |
| server.affinity | object | `{}` (defaults to the global.affinity preset) | Assign custom [affinity] rules to the deployment |
| server.service | object | `{"port":4000,"type":"ClusterIP"}` | This is for setting up a service [more information](https://kubernetes.io/docs/concepts/services-networking/service/) |
| writer.name | string | `"writer"` |  |
| writer.replicas | int | `1` |  |
| writer.image.registry | string | `"513558712013.dkr.ecr.us-east-1.amazonaws.com"` |  |
| writer.image.repository | string | `"currents/on-prem/writer"` |  |
| writer.image.tag | string | `""` | Override the image tag to deploy by setting this variable |
| writer.image.digest | string | `""` | Setting a digest will override any tag |
| writer.image.pullPolicy | string | `""` | defaults to global.image.pullPolicy |
| writer.deploymentStrategy | object | `{}` | Deployment update strategy for Currents deployment |
| writer.env | list | `[]` | Env variables to pass to the container |
| writer.volumes | list | `[]` | Additional volumes on the output Deployment definition |
| writer.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| writer.livenessProbe | object | `{"exec":{"command":["./node_modules/.bin/pm2","show","writer-service"]}}` | Liveness probe to check if the container is alive |
| writer.readinessProbe | object | `{"exec":{"command":["./node_modules/.bin/pm2","show","writer-service"]}}` | Readiness probe to check if the container is ready |
| writer.nodeSelector | object | `{}` (defaults to global.nodeSelector) | [Node selector] |
| writer.tolerations | list | `[]` (defaults to global.tolerations) | [Tolerations] for use with node taints |
| writer.affinity | object | `{}` (defaults to the global.affinity preset) | Assign custom [affinity] rules to the deployment |
| scheduler.name | string | `"scheduler"` |  |
| scheduler.image.registry | string | `"513558712013.dkr.ecr.us-east-1.amazonaws.com"` | The container registry to pull the manager image from |
| scheduler.image.repository | string | `"currents/on-prem/scheduler"` | The container image for Currents Server API |
| scheduler.image.tag | string | `""` | Override the image tag to deploy by setting this variable |
| scheduler.image.digest | string | `""` | Setting a digest will override any tag |
| scheduler.image.pullPolicy | string | `""` | defaults to global.image.pullPolicy |
| scheduler.startup.persistence | object | See [values.yaml] for default values | Persistence settings used to optimize startup tasks (avoid rerun startup tasks on restart) |
| scheduler.deploymentStrategy | object | `{"type":"Recreate"}` | Deployment update strategy for Currents deployment. [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy) |
| scheduler.env | list | `[]` | Env variables to pass to the container |
| scheduler.volumes | list | `[]` | Additional volumes on the output Deployment definition |
| scheduler.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| scheduler.livenessProbe | object | `{"exec":{"command":["./node_modules/.bin/pm2","show","dist"]}}` | Liveness probe to check if the container is alive |
| scheduler.readinessProbe | object | `{"exec":{"command":["./node_modules/.bin/pm2","show","dist"]}}` | Readiness probe to check if the container is ready |
| scheduler.nodeSelector | object | `{}` (defaults to global.nodeSelector) | [Node selector] |
| scheduler.tolerations | list | `[]` (defaults to global.tolerations) | [Tolerations] for use with node taints |
| scheduler.affinity | object | `{}` (defaults to the global.affinity preset) | Assign custom [affinity] rules to the deployment |
| changestreams.name | string | `"change-streams"` |  |
| changestreams.image.registry | string | `"513558712013.dkr.ecr.us-east-1.amazonaws.com"` | The container registry to pull the manager image from. |
| changestreams.image.repository | string | `"currents/on-prem/change-streams"` | The container image for Currents Change Streams Image |
| changestreams.image.tag | string | `""` | Override the image tag to deploy by setting this variable |
| changestreams.image.digest | string | `""` | Setting a digest will override any tag |
| changestreams.image.pullPolicy | string | `""` | defaults to global.image.pullPolicy |
| changestreams.deploymentStrategy | object | `{"type":"Recreate"}` | Deployment update strategy for Currents deployment. [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy) |
| changestreams.env | list | `[]` | Env variables to pass to the container |
| changestreams.volumes | list | `[]` | Additional volumes on the output Deployment definition |
| changestreams.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| changestreams.nodeSelector | object | `{}` (defaults to global.nodeSelector) | [Node selector] |
| changestreams.tolerations | list | `[]` (defaults to global.tolerations) | [Tolerations] for use with node taints |
| changestreams.affinity | object | `{}` (defaults to the global.affinity preset) | Assign custom [affinity] rules to the deployment |
| webhooks.name | string | `"webhooks"` |  |
| webhooks.image.registry | string | `"513558712013.dkr.ecr.us-east-1.amazonaws.com"` |  |
| webhooks.image.repository | string | `"currents/on-prem/webhooks"` |  |
| webhooks.image.tag | string | `""` | Override the image tag to deploy by setting this variable |
| webhooks.image.digest | string | `""` | Setting a digest will override any tag |
| webhooks.image.pullPolicy | string | `""` | defaults to global.image.pullPolicy |
| webhooks.deploymentStrategy | object | `{"type":"Recreate"}` | Deployment update strategy for Currents deployment. [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy) |
| webhooks.env | list | `[]` | Env variables to pass to the container |
| webhooks.volumes | list | `[]` | Additional volumes on the output Deployment definition |
| webhooks.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| webhooks.livenessProbe | object | `{"exec":{"command":["./node_modules/.bin/pm2","show","dist"]}}` | Liveness probe to check if the container is alive |
| webhooks.readinessProbe | object | `{"exec":{"command":["./node_modules/.bin/pm2","show","dist"]}}` | Readiness probe to check if the container is ready |
| webhooks.nodeSelector | object | `{}` (defaults to global.nodeSelector) | [Node selector] |
| webhooks.tolerations | list | `[]` (defaults to global.tolerations) | [Tolerations] for use with node taints |
| webhooks.affinity | object | `{}` (defaults to the global.affinity preset) | Assign custom [affinity] rules to the deployment |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | If not set and create is true, a name is generated using the fullname template | The name of the service account to use. |
| serviceAccount.annotations | object | `{}` | Optional additional annotations to add to the Service Account. Templates are allowed for both keys and values. |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| redis.image.repository | string | `"redis/redis-stack-server"` |  |
| redis.image.tag | string | `"7.2.0-v15"` |  |
| redis.commonConfiguration | string | `"loadmodule /opt/redis-stack/lib/rejson.so"` |  |
| redis.architecture | string | `"standalone"` |  |
| redis.auth.enabled | bool | `false` |  |
| redis.master.resourcesPreset | string | `"none"` |  |
| redis.replica.resourcesPreset | string | `"none"` |  |
| redis.sentinel.resourcesPreset | string | `"none"` |  |
| redis.metrics.resourcesPreset | string | `"none"` |  |
| redis.volumePermissions.resourcesPreset | string | `"none"` |  |
| redis.sysctl.resourcesPreset | string | `"none"` |  |

[values.yaml]: https://github.com/currents-dev/helm-charts/blob/main/charts/currents/values.yaml