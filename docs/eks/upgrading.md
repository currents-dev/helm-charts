# Upgrading Currents on EKS

This guide covers upgrading an existing Currents deployment installed with the Helm chart on EKS.

For reference, the Docker Compose environment has a separate upgrade flow: [Upgrading Currents On-Prem](https://github.com/currents-dev/docker/blob/main/docs/upgrading.md).

## Before You Begin

1. Check the chart [CHANGELOG](https://github.com/currents-dev/helm-charts/blob/main/CHANGELOG.md) for the target release.
2. Review any breaking changes and required values or secrets updates.
3. Upgrading from `0.8.x` to `1.0.0`? Follow [Upgrading to Chart 1.0](./upgrade-1.0.md) first: it changes SAML SSO and needs a second bucket.

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

## Index Builds Before an Upgrade

A release that declares a new index builds it during the upgrade, and the upgrade is not finished until the build is. On a large `instances` collection that has taken about an hour.

Before any pod rolls, the chart runs a `pre-upgrade` hook Job, `currents-index-check`, that reads what the build would cost. It only reads. If the estimate is over `indexes.preUpgrade.thresholdSeconds` (600 by default), the Job fails and Helm stops the upgrade with the running release untouched:

```
Error: UPGRADE FAILED: pre-upgrade hooks failed: job currents-index-check failed: BackoffLimitExceeded
```

**Helm does not print the Job's output**, and the output is the part you need — the estimate, the collections and the indexes. Read it from the pod, which is kept for this:

```bash
kubectl logs -n currents job/currents-index-check
```

```
Index build estimated at 64 minutes, which is over the limit of 10 minutes.

  instances: 109.0 GB, about 62 minutes (createdAt_1)

Estimated at 30.0 MB/s, the built-in default — this deployment has recorded no index builds of its own, so the real build may be several times faster.
```

That last line matters. Until an upgrade has recorded a build, the estimate uses a deliberately slow rate, so a first upgrade can stop on a build that is really much quicker. Once a build has been recorded the estimate uses this deployment's own measured rate and the figure is worth trusting.

### Ways Forward

Build the indexes before the upgrade, while the running release keeps serving. Nothing is down for it, and the build records a measured rate that later estimates use.

The build has to come from the image you are upgrading **to**: the running release does not declare the new indexes, so running `sync-indexes` inside a current pod rebuilds what is already there. Render the same Job the hook would run, at the target version and under a name of its own, and apply it:

```bash
helm template currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  --version <target-chart-version> \
  -f currents-helm-config.yaml \
  --set indexes.preUpgrade.mode=build \
  --set indexes.name=index-build \
  --show-only templates/indexes/pre-upgrade-job.yaml \
  | kubectl apply -n currents -f -

kubectl logs -n currents -f job/currents-index-build
```

`helm template` reads the chart and writes nothing to the cluster, so `--version` is what picks the image — pass the version you are about to upgrade to. A `currents.imageTag` pinned in your values file wins here exactly as it will during the upgrade. `--set indexes.name=index-build` gives the Job a name of its own, so it neither collides with `currents-index-check` nor deletes the failed check's log. The rendered Job still carries its `helm.sh/hook` annotations; outside of Helm they are ordinary annotations and `kubectl` ignores them.

Index builds read whole collections and saturate the secondaries the API reads from, so pick a quiet window. This is the same work the upgrade would do, moved to a time you choose rather than one Helm picks.

When the Job completes, remove it and upgrade as usual — the check finds nothing pending and passes:

```bash
kubectl delete job -n currents currents-index-build
```

Or accept the downtime and upgrade anyway:

```bash
helm upgrade --install currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  -f currents-helm-config.yaml \
  --set indexes.preUpgrade.mode=off
```

Or have the hook build them as part of the upgrade. Helm waits for the whole build, so raise `--timeout` past the estimate — otherwise Helm gives up partway and marks the release failed:

```bash
helm upgrade --install currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  -f currents-helm-config.yaml \
  --set indexes.preUpgrade.mode=build \
  --timeout 90m
```

To see what an upgrade would build without upgrading, run the plan against the running release:

```bash
kubectl exec -n currents deploy/currents-scheduler -- \
  node /app/packages/mongo/dist/scripts/migrate.js index-plan
```

This reports the indexes the running version declares, which says nothing about what a newer chart adds. For that, render the check Job the same way as the build above with `--set indexes.preUpgrade.mode=gate`: it reads the plan from the target image and leaves the database alone. It exits non-zero when the estimate is over the threshold, so the Job shows as failed even though the read succeeded; the log is the answer either way.

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

The scheduler component runs startup tasks (including migrations) on startup and logs `Startup tasks complete` when they finish. On a large dataset they can take several minutes. The scheduler pod reports ready while they run, so a finished `kubectl rollout status` doesn't mean the migrations are done.

Check scheduler logs during/after upgrades:

```bash
kubectl logs -n currents deploy/currents-scheduler --tail=200
```

If a migration fails, for example with a ClickHouse `Timeout error.` on a busy cluster, the scheduler logs the error and keeps running, but the remaining migrations don't run until it starts again. Restart it:

```bash
kubectl rollout restart deploy/currents-scheduler -n currents
```

Finished migrations are skipped, and an interrupted backfill skips the records it already updated, so a restart is safe to repeat.

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

### Upgrade Stopped by the Index Check

```
Error: UPGRADE FAILED: pre-upgrade hooks failed: job currents-index-check failed
```

Read the Job's log and pick a way forward: [Index Builds Before an Upgrade](#index-builds-before-an-upgrade).

If the log shows a connection error rather than an estimate, or the Job ends in `DeadlineExceeded`, MongoDB is not answering the chart's `currents.mongoConnection` secret — the same connection every service uses. Fix that before upgrading; the check is reporting a real problem, not getting in the way.

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
