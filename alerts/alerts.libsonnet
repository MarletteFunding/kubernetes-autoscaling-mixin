{
  prometheusAlerts+:: {
    groups+: [
      {
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
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            'for': '5m',
            annotations: {
              summary: 'Karpenter has Cloud Provider Errors.',
              description: 'The Karpenter provider {{ $labels.provider }} with the controller {{ $labels.controller }} has errors with the method {{ $labels.method }}.',
              dashboard_url: $._config.karpenterPerformanceDashboardUrl,
            },
          },
        ],
      },
    ],
  },
}
