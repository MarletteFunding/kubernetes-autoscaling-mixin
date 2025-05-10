{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  local clusterLabel = { clusterLabel: $._config.clusterLabel },
  prometheusAlerts+:: {
    groups+: std.prune([
      if $._config.karpenter.enabled then {
        local karpenterConfig = $._config.karpenter + clusterLabel,
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
              ) by (%(clusterLabel)s, namespace, job, provider, controller, method) > 0
            ||| % karpenterConfig,
            labels: {
              severity: 'warning',
            },
            'for': '5m',
            annotations: {
              summary: 'Karpenter has Cloud Provider Errors.',
              description: 'The Karpenter provider {{ $labels.provider }} with the controller {{ $labels.controller }} has errors with the method {{ $labels.method }}.',
              dashboard_url: $._config.karpenter.karpenterPerformanceDashboardUrl + clusterVariableQueryString,
            },
          },
          {
            alert: 'KarpenterNodeClaimsTerminationDurationHigh',
            expr: |||
              sum(
                karpenter_nodeclaims_termination_duration_seconds_sum{
                  %(karpenterSelector)s
                }
              ) by (%(clusterLabel)s, namespace, job, nodepool)
              /
              sum(
                karpenter_nodeclaims_termination_duration_seconds_count{
                  %(karpenterSelector)s
                }
              ) by (%(clusterLabel)s, namespace, job, nodepool) > %(nodeclaimTerminationThreshold)s
            ||| % karpenterConfig,
            labels: {
              severity: 'warning',
            },
            'for': '15m',
            annotations: {
              summary: 'Karpenter Node Claims Termination Duration is High.',
              description: 'The average node claim termination duration in Karpenter has exceeded %s minutes for more than 15 minutes in nodepool {{ $labels.nodepool }}. This may indicate cloud provider issues or improper instance termination handling.' % std.toString($._config.karpenter.nodeclaimTerminationThreshold / 60),
              dashboard_url: $._config.karpenter.karpenterActivityDashboardUrl + clusterVariableQueryString,
            },
          },
          {
            alert: 'KarpenterNodepoolNearCapacity',
            annotations: {
              summary: 'Karpenter Nodepool near capacity.',
              description: 'The resource {{ $labels.resource_type }} in the Karpenter node pool {{ $labels.nodepool }} is nearing its limit. Consider scaling or adding resources.',
              dashboard_url: $._config.karpenter.karpenterOverviewDashboardUrl + clusterVariableQueryString,
            },
            expr: |||
              sum (
                karpenter_nodepools_usage{%(karpenterSelector)s}
              ) by (%(clusterLabel)s, namespace, job, nodepool, resource_type)
              /
              sum (
                karpenter_nodepools_limit{%(karpenterSelector)s}
              ) by (%(clusterLabel)s, namespace, job, nodepool, resource_type)
              * 100 > %(nodepoolCapacityThreshold)s
            ||| % karpenterConfig,
            'for': '15m',
            labels: {
              severity: 'warning',
            },
          },
        ],
      },
      if $._config.clusterAutoscaler.enabled then {
        local clusterAutoscalerConfig = $._config.clusterAutoscaler + clusterLabel,
        name: 'cluster-autoscaler',
        rules: [
          {
            alert: 'ClusterAutoscalerNodeCountNearCapacity',
            annotations: {
              summary: 'Cluster Autoscaler Node Count near Capacity.',
              description: 'The node count for the cluster autoscaler job {{ $labels.job }} is reaching max limit. Consider scaling node groups.',
              dashboard_url: $._config.clusterAutoscaler.clusterAutoscalerDashboardUrl + clusterVariableQueryString,
            },
            expr: |||
              sum (
                cluster_autoscaler_nodes_count{%(clusterAutoscalerSelector)s}
              ) by (%(clusterLabel)s, namespace, job)
              /
              sum (
                cluster_autoscaler_max_nodes_count{%(clusterAutoscalerSelector)s}
              ) by (%(clusterLabel)s, namespace, job)
              * 100 > %(nodeCountCapacityThreshold)s
            ||| % clusterAutoscalerConfig,
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
              dashboard_url: $._config.clusterAutoscaler.clusterAutoscalerDashboardUrl + clusterVariableQueryString,
            },
            expr: |||
              sum (
                cluster_autoscaler_unschedulable_pods_count{%(clusterAutoscalerSelector)s}
              ) by (%(clusterLabel)s, namespace, job)
              > 0
            ||| % clusterAutoscalerConfig,
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
