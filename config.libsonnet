local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local annotation = g.dashboard.annotation;

{
  _config+:: {
    // Bypasses grafana.com/dashboards validator
    bypassDashboardValidation: {
      __inputs: [],
      __requires: [],
    },

    kubernetesAutoscalingSelector: 'job=~"kubernetes-autoscaling-mixin"',

    grafanaUrl: 'https://grafana.com',

    pdbDashboardUid: 'kubernetes-autoscaling-mixin-pdb-jkwq',
    hpaDashboardUid: 'kubernetes-autoscaling-mixin-hpa-jkwq',
    vpDashboardUid: 'kubernetes-autoscaling-mixin-vp-jkwq',
    clusterAutoscalerDashboardUid: 'kubernetes-autoscaling-mixin-ca-jkwq',
    karpenterOverviewDashboardUid: 'kubernetes-autoscaling-mixin-kover-jkwq',
    karpenterActivityDashboardUid: 'kubernetes-autoscaling-mixin-kact-jkwq',
    karpenterPerformanceDashboardUid: 'kubernetes-autoscaling-mixin-kperf-jkwq',

    clusterAutoscaler: {
      enabled: false,
    },

    karpenter: {
      enabled: false,
    },

    overviewDashboardUrl: '%s/d/%s/kubernetes-autoscaling-mixin-overview' % [self.grafanaUrl, self.overviewDashboardUid],
    requestsByViewDashboardUrl: '%s/d/%s/kubernetes-autoscaling-mixin-requests-by-view' % [self.grafanaUrl, self.requestsByViewDashboardUid],

    tags: ['kubernetes', 'autoscaling', 'kubernetes-autoscaling-mixin'],

    // Custom annotations to display in graphs
    annotation: {
      enabled: false,
      name: 'Custom Annotation',
      datasource: '-- Grafana --',
      iconColor: 'green',
      tags: [],
    },

    customAnnotation:: if $._config.annotation.enabled then
      annotation.withName($._config.annotation.name) +
      annotation.withIconColor($._config.annotation.iconColor) +
      annotation.withHide(false) +
      annotation.datasource.withUid($._config.annotation.datasource) +
      annotation.target.withMatchAny(true) +
      annotation.target.withTags($._config.annotation.tags) +
      annotation.target.withType('tags')
    else {},
  },
}
