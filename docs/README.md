# Currents Self-Hosted Documentation

Currents on-premise installation is a series of microservices provided as container images that are installed into a Kubernetes Cluster using the Currents Helm Chart.

The Currents Helm Chart is stateless, so depends on being connected to stateful services like a Database and Object Storage. These connected stateful services can be deployed inside the Kubernetes cluster alongside Currents, or outside the cluster.

## Resources

- [🚀 Start Here: EKS Quickstart](./eks/quickstart.md)
- [EKS Upgrade Guide](./eks/upgrading.md)
- [Upgrading to Chart 1.0](./eks/upgrade-1.0.md)
- [Docs for chart 0.8.x](https://currents-dev.github.io/helm-charts/0.8/docs/)
- [Importing Organization Data (Cloud → Self-Hosted Migration)](./org-data-import.md)
- [Development Guide](./developer-guide/README.md)
- [Support Policy](./support.md)
- [Configuration Reference](configuration.md)
- [IAM Resources](./eks/iam.md)

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Chart Versions

The chart follows semantic versioning from `1.0.0`:

- A patch release (`1.0.x`) fixes the chart or moves to newer images, with no values to change.
- A minor release (`1.x.0`) adds values. Existing values keep working.
- A major release (`2.0.0`) can rename, remove or change the meaning of values, and comes with an upgrade guide.

The values in the [Configuration Reference](./configuration.md) are the chart's interface. Templates, helpers and resource names are not: they can change in any release.

Each chart version deploys one Currents image tag, its `appVersion`.

## Upstream Services

- The self-hosted solution requires an existing Identity Provider for access provisioning.
- The in-cluster setups for MongoDB, ClickHouse and RustFS in [Currents Service Dependencies](./eks/dependencies.md) are for evaluation. In production, run them yourself or use managed services. The Redis the chart can install suits up to about 100 runs a day; see [Redis](./eks/dependencies.md#redis).
- Currents team doesn't provide support for the upstream services (MongoDB, ElasticSearch, Clickhouse), see [Support Policy](./support.md).

## Known Limitations

The following features are not fully availabe for self-hosted version. If you need them let us know in advance:

- Code coverage collection and reporting
- BitBucket and MS Team integrations are still WIP
  
