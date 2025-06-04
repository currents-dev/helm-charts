# Currents Self-Hosted Documentation

Currents on-premise installation is a series of microservices provided as container images that are installed into a Kubernetes Cluster using the Currents Helm Chart.

The Currents Helm Chart is stateless, so depends on being connected to stateful services like a Database and Object Storage. These connected stateful services can be deployed inside the Kubernetes cluster alongside Currents, or outside the cluster.

## Resources

- [🚀 Start Here: EKS Quickstart](./eks/quickstart.md)
- [Development Guide](./developer-guide/README.md)
- [Support Policy](./support.md)
- [Configuration Reference](configuration.md)
- [IAM Resources](./eks/iam.md)

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Upstream Services

- The self-hosted solution requires an existing Identity Provider for access provisioning.
- The recommended configuration for the stateful services (MongoDB, ElasticSearch, Clickhouse) may not be adequate for all production loads.
- Currents team doesn't provide support for the upstream services (MongoDB, ElasticSearch, Clickhouse), see [Support Policy](./support.md).

## Known Limitations

The following features are not fully availabe for self-hosted version. If you need them let us know in advance:

- Code coverage collection and reporting
- BitBucket and MS Team integrations are still WIP
  
