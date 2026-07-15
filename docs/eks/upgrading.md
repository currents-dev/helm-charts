# Upgrading Currents on EKS

This guide covers upgrading an existing Currents deployment installed with the Helm chart on EKS.

For reference, the Docker Compose environment has a separate upgrade flow: [Upgrading Currents On-Prem](https://github.com/currents-dev/docker/blob/main/docs/upgrading.md).

## Before You Begin

1. Check the chart [CHANGELOG](https://github.com/currents-dev/helm-charts/blob/main/CHANGELOG.md) for the target release.
2. Review any breaking changes and required values or secrets updates.

Infrastructure backups and third-party dependencies are customer-managed. See [Currents Service Dependencies](./dependencies.md) and [Support Policy](../support.md).

## How Versioning Works

Two versions matter during upgrades:

- **Chart version** (`version` in `Chart.yaml`) controls chart templates and defaults.
- **App image version** (`appVersion` / `currents.imageTag`) controls Currents service container images.

By default, `helm upgrade --install` without `--version` upgrades to the latest published chart. You can pin the chart version with `--version`.

## Upgrade Types

### Chart/Image Updates (No Config Changes)

Use this when release notes do not require values or secret changes:

```bash
kubectl config set-context --current --namespace=currents

helm upgrade --install currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  -f currents-helm-config.yaml
```

To target a specific chart version:

```bash
helm upgrade --install currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  --version 0.7.0 \
  -f currents-helm-config.yaml
```

### Updates with Values File Changes

Use this when release notes mention new or renamed values:

1. Compare your `currents-helm-config.yaml` with the latest chart values reference:
   - [Currents values.yaml](https://github.com/currents-dev/helm-charts/blob/main/charts/currents/values.yaml)
   - [Configuration Reference](../configuration.md)
2. Add/update required values in your `currents-helm-config.yaml`.
3. Run `helm upgrade --install` with the updated file.

### Updates with New Secrets

Use this when release notes require new secrets:

1. Create any required Kubernetes secrets before the upgrade (for example auth, SMTP, SSO, storage).
2. Ensure your values file references those secret names and keys.
3. Run `helm upgrade --install`.

## Running the Upgrade

Recommended upgrade command:

```bash
kubectl config set-context --current --namespace=currents

helm upgrade --install currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  -f currents-helm-config.yaml
```

Optional: if you use the Helm diff plugin, preview changes first:

```bash
helm diff upgrade currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  -f currents-helm-config.yaml
```

Watch rollout:

```bash
kubectl get pods
kubectl rollout status deploy -l app.kubernetes.io/instance=currents --timeout=5m
```

## Version Checking

Check installed chart and app version:

```bash
helm list -n currents
```

Check applied values:

```bash
helm get values currents -n currents
```

Check running container images:

```bash
kubectl get pods -n currents -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[*].image
```

## Database Migrations and Startup Tasks

The scheduler component runs startup tasks (including migrations) on startup.

Check scheduler logs during/after upgrades:

```bash
kubectl logs -n currents deploy/currents-scheduler --tail=200
```

## Rollback

If you need to rollback:

```bash
helm history currents -n currents
helm rollback currents <revision> -n currents
```

Then verify pod health:

```bash
kubectl get pods -n currents
```

## Troubleshooting

### Pods Do Not Start (CrashLoopBackOff / Pending)

```bash
kubectl get pods -n currents
kubectl describe pod <pod-name> -n currents
kubectl logs <pod-name> -n currents --all-containers --tail=200
```

### Connection Errors in Logs

If services report MongoDB/ClickHouse/Redis/object storage connection errors, dependencies may still be initializing. Restart the affected deployment:

```bash
kubectl rollout restart deploy/<deployment-name> -n currents
```

### Missing Secrets or Config

If pods fail with missing env var or secret errors:

```bash
kubectl get secrets -n currents
helm get values currents -n currents
```

Confirm secret names/keys match the values in [Configuration Reference](../configuration.md).

### Image Pull Errors

If pods fail with ECR pull errors, verify EKS IAM access for image pulls:

- [IAM Resources](./iam.md)

## Out of Scope

This guide covers upgrading Currents Helm chart releases and application images.

Upgrading third-party infrastructure (MongoDB operators, ClickHouse operators, storage platform, cluster components) is customer-managed. See:

- [Currents Service Dependencies](./dependencies.md)
- [Support Policy](../support.md)
