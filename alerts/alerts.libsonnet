{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'kubernetes-autoscaling-mixin',
        rules: [
          {
            alert: 'Kubernetes / AutoscalingMigrationsUnapplied',
            expr: |||
              sum(
                kubernetes-autoscaling-mixin_migrations_unapplied_total{
                  %(kubernetesAutoscalingSelector)s
                }
              ) by (namespace, job)
              > 0
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            'for': '15m',
            annotations: {
              summary: 'Kubernetes / Autoscaling has unapplied migrations.',
              description: 'The job {{ $labels.job }} has unapplied migrations.',
              dashboard_url: $._config.overviewDashboardUrl + '?var-namespace={{ $labels.namespace }}&var-job={{ $labels.job }}',
            },
          },
          {
            alert: 'Kubernetes / AutoscalingDatabaseException',
            expr: |||
              sum (
                increase(
                  kubernetes-autoscaling-mixin_db_errors_total{
                    %(kubernetesAutoscalingSelector)s
                  }[10m]
                )
              ) by (type, namespace, job)
              > 0
            ||| % $._config,
            labels: {
              severity: 'info',
            },
            annotations: {
              summary: 'Kubernetes / Autoscaling database exception.',
              description: 'The job {{ $labels.job }} has hit the database exception {{ $labels.type }}.',
              dashboard_url: $._config.overviewDashboardUrl + '?var-namespace={{ $labels.namespace }}&var-job={{ $labels.job }}',
            },
          },
          {
            alert: 'Kubernetes / AutoscalingHighHttp4xxErrorRate',
            expr: |||
              sum(
                rate(
                  kubernetes-autoscaling-mixin_http_responses_total_by_status_view_method_total{
                    %(kubernetesAutoscalingSelector)s,
                    status=~"^4.*",
                    view!~"%(kubernetes-autoscaling-mixinIgnoredViews)s"
                  }[%(kubernetes-autoscaling-mixin4xxInterval)s]
                )
              )  by (namespace, job, view)
              /
              sum(
                rate(
                  kubernetes-autoscaling-mixin_http_responses_total_by_status_view_method_total{
                    %(kubernetesAutoscalingSelector)s,
                    view!~"%(kubernetes-autoscaling-mixinIgnoredViews)s"
                  }[%(kubernetes-autoscaling-mixin4xxInterval)s]
                )
              )  by (namespace, job, view)
              * 100 > %(kubernetes-autoscaling-mixin4xxThreshold)s
            ||| % $._config,
            'for': '1m',
            annotations: {
              summary: 'Kubernetes / Autoscaling high HTTP 4xx error rate.',
              description: 'More than %(kubernetes-autoscaling-mixin4xxThreshold)s%% HTTP requests with status 4xx for {{ $labels.job }}/{{ $labels.view }} the past %(kubernetes-autoscaling-mixin4xxInterval)s.' % $._config,
              dashboard_url: $._config.requestsByViewDashboardUrl + '?var-namespace={{ $labels.namespace }}&var-job={{ $labels.job }}&var-view={{ $labels.view }}',
            },
            labels: {
              severity: $._config.kubernetes-autoscaling-mixin4xxSeverity,
            },
          },
          {
            alert: 'Kubernetes / AutoscalingHighHttp5xxErrorRate',
            expr: |||
              sum(
                rate(
                  kubernetes-autoscaling-mixin_http_responses_total_by_status_view_method_total{
                    %(kubernetesAutoscalingSelector)s,
                    status=~"^5.*",
                    view!~"%(kubernetes-autoscaling-mixinIgnoredViews)s"
                  }[%(kubernetes-autoscaling-mixin5xxInterval)s]
                )
              )  by (namespace, job, view)
              /
              sum(
                rate(
                  kubernetes-autoscaling-mixin_http_responses_total_by_status_view_method_total{
                    %(kubernetesAutoscalingSelector)s,
                    view!~"%(kubernetes-autoscaling-mixinIgnoredViews)s"
                  }[%(kubernetes-autoscaling-mixin5xxInterval)s]
                )
              )  by (namespace, job, view)
              * 100 > %(kubernetes-autoscaling-mixin5xxThreshold)s
            ||| % $._config,
            'for': '1m',
            annotations: {
              summary: 'Kubernetes / Autoscaling high HTTP 5xx error rate.',
              description: 'More than %(kubernetes-autoscaling-mixin5xxThreshold)s%% HTTP requests with status 5xx for {{ $labels.job }}/{{ $labels.view }} the past %(kubernetes-autoscaling-mixin5xxInterval)s.' % $._config,
              dashboard_url: $._config.requestsByViewDashboardUrl + '?var-namespace={{ $labels.namespace }}&var-job={{ $labels.job }}&var-view={{ $labels.view }}',
            },
            labels: {
              severity: $._config.kubernetes-autoscaling-mixin5xxSeverity,
            },
          },
        ],
      },
    ],
  },
}
