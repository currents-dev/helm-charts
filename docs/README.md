# Currents On-Premise Documentation

Currents on-premise installation is a series of microservices provided as container images that are installed into a Kubernetes Cluster using the Currents Helm Chart.

The Currents Helm Chart is stateless, so depends on being connected to stateful services like a Database and Object Storage. These connected stateful services can be deployed inside the Kubernetes cluster alongside Currents, or outside the cluster.

## Resources

- [🚀 Start Here: EKS Quickstart](./eks/quickstart.md)
- [Development Guide](./developer-guide/README.md)
- [Support Policy](./support.md)
- [Configuration Reference](configuration.md)
- [IAM Eesources](iam.md)

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Known Limitations

- Currents On Premise does not have multi-user or any auth support at this time. It’s best deployed in a private network.
- Coverage collection is currently not available
- Not all the integrations are working, but may still be visible in the UI.
- GitLab, Slack, and the Generic Webhooks are working
- The documented configuration for the connected stateful services (mongo, elastic) are not definitive, and may not be adequate for all production setups.
- In our cloud offering, [Currents.dev](https://currents.dev) relies on the production resources of the ElasticSearch, and MongoDB teams to run our stateful services. If you do not have the expertise in house for these services, Currents.dev is also not able to provide those resources, and you should instead consider getting support from the upstream service providers.
