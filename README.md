# Currents Helm Chart Repository for Kubernetes

This repo contains the Currents Helm chart.

## Adding the Currents Helm Repo

The Currents Helm repository can be added using the `helm repo add` command, like
in the following example:

```
$ helm repo add currents https://currents-dev.github.io/helm-charts
"currents" has been added to your repositories
```

## Installing the Currents Helm Chart

> Note that the Currents containers are only available via a private registry to our OnPrem Beta Customers. Please context Currents Support for if you are interested in joining this program.

The chart can be installed using:

```
helm upgrade --install  -f config.yaml currents currents/currents
```

Where `config.yaml` is your configuration file. See the [Chart Readme](https://github.com/currents-dev/helm-charts) for all configurations options.