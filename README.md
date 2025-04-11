# Currents On-Premise Repo

Currents on-premise installation is a series of microservices provided as container images that are installed into a Kubernetes Cluster using the Currents Helm Chart.

Read the [documentation](./docs/README.md).

## Release Process

### Overview

The release process for the Currents Helm Chart involves

- Checkout new release branch
- Updating appVersion,imageTag to the latest image.
- Bump the Helm chart version
- Push the branch up to GitHub
- Merge the release to `main`
- Run the GitHub actions release task

### Scripts

- `scripts/update-version.sh` - Updates the tagged image version used in the charts.


### Example of performing a release

- Run: 
  - `git checkout -b release/currents-0.x.x`
  - Use the desired chart version number in the branch name
- Run:
  - `./scripts/update-version.sh -t <image tag name> -v <new chart version>`
  - Updates the appVersion and imageTag: ex: `./scripts/update-version.sh -t 2025-04-13-001 -v 0.2.2`
- Commit and push the branch up to GitHub, create a release PR
- Merge the PR to `main` once the tests have passed
- Trigger the `Release Charts` GitHub workflow action manually from the GitHub Actions UI
  - This will package the chart and create a new GitHub release with its artifact
  - This will also automatically update our Helm Chart repository index, making the new chart visible to users of our Helm repository   