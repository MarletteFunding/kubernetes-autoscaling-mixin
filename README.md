# Prometheus Monitoring Mixin for Kubernetes Autoscaling

A set of Grafana dashboards and Prometheus alerts for Kubernetes Autoscaling using the metrics from Kube-state-metrics, Karpenter and Cluster-autoscaler.

## Dashboards

The mixin provides the following dashboards:

- Kubernetes Autoscaling
    - Pod Disruption Budgets
    - Horizontal Pod Autoscalers
    - Vertical Pod Autoscalers
- Cluster Autoscaler
- Karpenter
    - Overview
    - Activity
    - Performance

There are also generated dashboards in the `./dashboards_out` directory.

There are alerts for the following components currently:

- Karpenter

VPA, Karpenter and Cluster Autoscaler are configurable in the `config.libsonnet` file. They can be disabled by setting the `enabled` field to `false`.

## How to use

This mixin is designed to be vendored into the repo with your infrastructure config.
To do this, use [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler):

You then have three options for deploying your dashboards

1. Generate the config files and deploy them yourself
2. Use jsonnet to deploy this mixin along with Prometheus and Grafana
3. Use prometheus-operator to deploy this mixin

Or import the dashboard using json in `./dashboards_out`, alternatively import them from the `Grafana.com` dashboard page.

## Generate config files

You can manually generate the alerts, dashboards and rules files, but first you
must install some tools:

```sh
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
brew install jsonnet
```

Then, grab the mixin and its dependencies:

```sh
git clone https://github.com/adinhodovic/kubernetes-autoscaling-mixin-mixin
cd kubernetes-autoscaling-mixin-mixin
jb install
```

Finally, build the mixin:

```sh
make prometheus_alerts.yaml
make dashboards_out
```

The `prometheus_alerts.yaml` file then need to passed
to your Prometheus server, and the files in `dashboards_out` need to be imported
into you Grafana server. The exact details will depending on how you deploy your
monitoring stack.

### Configuration

This mixin has its configuration in the `config.libsonnet` file. You can disable the alerts for VPA, Karpenter and Cluster Autoscaler by setting the `enabled` field to `false`.

```jsonnet
{
  _config+:: {
    vpa+:: {
      enabled: false,
    },
    karpenter+:: {
      enabled: false,
    },
    clusterAutoscaler+:: {
      enabled: false,
    },
  },
}
```

## Alerts

The mixin follows the [monitoring-mixins guidelines](https://github.com/monitoring-mixins/docs#guidelines-for-alert-names-labels-and-annotations) for alerts.
