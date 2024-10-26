{
  prometheusAlerts+:: {
    groups+: std.prune([
      if $._config.karpenter.enabled then {
        name: 'karpenter',
        rules: [
          {
            alert: 'KarpenterCloudProviderErrors',
            expr: |||
              sum(
                increase(
                  karpenter_cloudprovider_errors_total{
                    %(karpenterSelector)s
                  }[5m]
                )
              ) by (namespace, job, provider, controller, method) > 0
            ||| % $._config.karpenter,
            labels: {
              severity: 'warning',
            },
            'for': '5m',
            annotations: {
              summary: 'Karpenter has Cloud Provider Errors.',
              description: 'The Karpenter provider {{ $labels.provider }} with the controller {{ $labels.controller }} has errors with the method {{ $labels.method }}.',
              dashboard_url: $._config.karpenter.karpenterPerformanceDashboardUrl,
            },
          },
          {
            alert: 'KarpenterNodepoolNearCapacity',
            annotations: {
              summary: 'Karpenter Nodepool near capacity.',
              description: 'The resource {{ $labels.resource_type }} in the Karpenter node pool {{ $labels.nodepool }} is nearing its limit. Consider scaling or adding resources.',
              dashboard_url: $._config.karpenter.karpenterOverviewDashboardUrl,
            },
            expr: |||
              sum (
                karpenter_nodepools_usage{%(karpenterSelector)s}
              ) by (namespace, job, nodepool, resource_type)
              /
              sum (
                karpenter_nodepools_limit{%(karpenterSelector)s}
              ) by (namespace, job, nodepool, resource_type)
              * 100 > %(nodepoolCapacityThreshold)s
            ||| % $._config.karpenter,
            'for': '15m',
            labels: {
              severity: 'warning',
            },
          },
        ],
      },
      if $._config.clusterAutoscaler.enabled then {
        name: 'cluster-autoscaler',
        rules: [
          {
            alert: 'ClusterAutoscalerNodeCountNearCapacity',
            annotations: {
              summary: 'Cluster Autoscaler Node Count near Capacity.',
              description: 'The node count for the cluster autoscaler job {{ $labels.job }} is reaching max limit. Consider scaling node groups.',
              dashboard_url: $._config.clusterAutoscaler.clusterAutoscalerDashboardUrl,
            },
            expr: |||
              sum (
                cluster_autoscaler_nodes_count{%(clusterAutoscalerSelector)s}
              ) by (namespace, job)
              /
              sum (
                cluster_autoscaler_max_nodes_count{%(clusterAutoscalerSelector)s}
              ) by (namespace, job)
              * 100 > %(nodeCountCapacityThreshold)s
            ||| % $._config.clusterAutoscaler,
            'for': '15m',
            labels: {
              severity: 'warning',
            },
          },
          {
            alert: 'ClusterAutoscalerUnschedulablePods',
            annotations: {
              summary: 'Pods Pending Scheduling - Cluster Node Group Scaling Required',
              description: 'The cluster currently has unschedulable pods, indicating resource shortages. Consider adding more nodes or increasing node group capacity.',
              dashboard_url: $._config.clusterAutoscaler.clusterAutoscalerDashboardUrl,
            },
            expr: |||
              sum (
                cluster_autoscaler_unschedulable_pods_count{%(clusterAutoscalerSelector)s}
              ) by (namespace, job)
              > 0
            ||| % $._config.clusterAutoscaler,
            'for': '15m',
            labels: {
              severity: 'warning',
            },
          },
        ],
      },
    ]),
  },
}
