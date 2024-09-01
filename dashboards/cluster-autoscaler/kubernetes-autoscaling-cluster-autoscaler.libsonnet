local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;
local prometheus = g.query.prometheus;

local statPanel = g.panel.stat;
local gaugePanel = g.panel.gauge;
local timeSeriesPanel = g.panel.timeSeries;

// Stat
local stOptions = statPanel.options;
local stStandardOptions = statPanel.standardOptions;
local stQueryOptions = statPanel.queryOptions;

// Gauge
local gaOptions = gaugePanel.options;
local gaStandardOptions = gaugePanel.standardOptions;
local gaQueryOptions = gaugePanel.queryOptions;

// Timeseries
local tsOptions = timeSeriesPanel.options;
local tsStandardOptions = timeSeriesPanel.standardOptions;
local tsQueryOptions = timeSeriesPanel.queryOptions;
local tsFieldConfig = timeSeriesPanel.fieldConfig;
local tsCustom = tsFieldConfig.defaults.custom;
local tsLegend = tsOptions.legend;

{
  grafanaDashboards+:: std.prune({

    local datasourceVariable =
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source'),

    local jobVariable =
      query.new(
        'job',
        'label_values(cluster_autoscaler_last_activity{}, job)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),


    local variables = [
      datasourceVariable,
      jobVariable,
    ],

    local caTotalNodesQuery = |||
      round(
        sum(
          cluster_autoscaler_nodes_count{
            job="$job"
          }
        )
      )
    |||,

    local caTotalNodesStatPanel =
      statPanel.new(
        'Total Nodes',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caTotalNodesQuery,
        )
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.1) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local caMaxNodesQuery = |||
      round(
        sum(
          cluster_autoscaler_max_nodes_count{
            job="$job"
          }
        )
      )
    |||,

    local caMaxNodesStatPanel =
      statPanel.new(
        'Max Nodes',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caMaxNodesQuery,
        )
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.1) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local caNodeGroupsQuery = |||
      round(
        sum(
          cluster_autoscaler_node_groups_count{
            job="$job"
          }
        )
      )
    |||,

    local caNodeGroupsStatPanel =
      statPanel.new(
        'Node Groups',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caNodeGroupsQuery,
        )
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.1) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local caHealthyNodesQuery = |||
      round(
        sum(
          cluster_autoscaler_nodes_count{
            job="$job"
          }
        ) /
        sum(
          cluster_autoscaler_nodes_count{
            job="$job",
            state="ready"
          }
        ) * 100
      )
    |||,

    local caHealthyNodesStatPanel =
      gaugePanel.new(
        'Healthy Nodes',
      ) +
      gaQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caHealthyNodesQuery,
        )
      ) +
      gaStandardOptions.withUnit('percent') +
      gaOptions.reduceOptions.withCalcs(['lastNotNull']) +
      gaStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.1) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local caSafeToScaleQuery = |||
      round(
        sum(
          cluster_autoscaler_cluster_safe_to_autoscale{
            job="$job"
          }
        )
      )
    |||,

    local caSafeToScaleStatPanel =
      statPanel.new(
        'Safe To Scale',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caSafeToScaleQuery,
        )
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.1) +
        stStandardOptions.threshold.step.withColor('green'),
      ]) +
      stStandardOptions.withMappings(
        stStandardOptions.mapping.ValueMap.withType() +
        stStandardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'No', color: 'red' },
            '1': { text: 'Yes', color: 'green' },
          }
        )
      ),

    local caNumberUnscheduledPodsQuery = |||
      round(
        sum(
          cluster_autoscaler_unschedulable_pods_count{
            job="$job"
          }
        )
      )
    |||,

    local caNumberUnscheduledPodsStatPanel =
      statPanel.new(
        'Unscheduled Pods',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caNumberUnscheduledPodsQuery,
        )
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']),

    local caLastScaleDownQuery = |||
      time() - sum(
        cluster_autoscaler_last_activity{
          job="$job",
          activity="scaleDown"
        }
      )
    |||,

    local caLastScaleDownStatPanel =
      statPanel.new(
        'Last Scale Down',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caLastScaleDownQuery,
        )
      ) +
      stStandardOptions.withUnit('s') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local caLastScaleUpQuery = |||
      time() - sum(
        cluster_autoscaler_last_activity{
          job="$job",
          activity="scaleUp"
        }
      )
    |||,

    local caLastScaleUpStatPanel =
      statPanel.new(
        'Last Scale Up',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caLastScaleUpQuery,
        )
      ) +
      stStandardOptions.withUnit('s') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local caUnschedulablePodsQuery = |||
      round(
        sum(
          increase(
            cluster_autoscaler_unschedulable_pods_count{
              job="$job"
            }[2m]
          )
        ) by (type)
      )
    |||,

    local caEvicedPodsQuery = |||
      round(
        sum(
          increase(
            cluster_autoscaler_evicted_pods_total{
              job="$job"
            }[2m]
          )
        )
      )
    |||,

    local caPodActivityTimeSeriesPanel =
      timeSeriesPanel.new(
        'Pod Activity',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            caUnschedulablePodsQuery,
          ) +
          prometheus.withLegendFormat('{{ type }}'),
          prometheus.new(
            '$datasource',
            caEvicedPodsQuery,
          ) +
          prometheus.withLegendFormat('Evicted Pods'),
        ]
      ) +
      tsStandardOptions.withUnit('short') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('bottom') +
      tsLegend.withCalcs(['lastNotNull', 'max']) +
      tsLegend.withSortBy('Last *') +
      tsLegend.withSortDesc(true) +
      tsCustom.withSpanNulls(false),

    local caNodeActivityQuery = |||
      round(
        sum(
          cluster_autoscaler_nodes_count{
            job="$job"
          }
        ) by (state)
      )
    |||,

    local caNodeActivityTimeSeriesPanel =
      timeSeriesPanel.new(
        'Node Activity',
      ) +
      tsQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          caNodeActivityQuery,
        ) +
        prometheus.withLegendFormat('{{ state }}')
      ) +
      tsStandardOptions.withUnit('short') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['lastNotNull', 'mean', 'max']) +
      tsLegend.withSortBy('Last *') +
      tsLegend.withSortDesc(true) +
      tsCustom.withSpanNulls(false),

    local caUnneededNodesQuery = |||
      round(
        sum(
          cluster_autoscaler_unneeded_nodes_count{
            job="$job"
          }
        )
      )
    |||,

    local caScaledUpNodesQuery = |||
      round(
        sum(
          increase(
            cluster_autoscaler_scaled_up_nodes_total{
              job="$job"
            }[2m]
          )
        )
      )
    |||,

    local caScaledDownNodesQuery = std.strReplace(caScaledUpNodesQuery, 'scaled_up', 'scaled_down'),

    local caAutoscalingActivityTimeSeriesPanel =
      timeSeriesPanel.new(
        'Autoscaling Activity',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            caTotalNodesQuery
          ) +
          prometheus.withLegendFormat('Total Nodes'),
          prometheus.new(
            '$datasource',
            caUnneededNodesQuery
          ) +
          prometheus.withLegendFormat('Unneeded Nodes'),
          prometheus.new(
            '$datasource',
            caScaledUpNodesQuery
          ) +
          prometheus.withLegendFormat('Scaled Up Nodes'),
          prometheus.new(
            '$datasource',
            caScaledDownNodesQuery
          ) +
          prometheus.withLegendFormat('Scaled Down Nodes'),
        ]
      ) +
      tsStandardOptions.withUnit('short') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['lastNotNull', 'mean', 'max']) +
      tsLegend.withSortBy('Last *') +
      tsLegend.withSortDesc(true) +
      tsCustom.withSpanNulls(false),

    local caSummaryRow =
      row.new(
        title='Summary',
      ),

    'kubernetes-autoscaling-mixin-ca.json': if $._config.clusterAutoscaler.enabled then
      $._config.bypassDashboardValidation +
      dashboard.new(
        'Kubernetes / Autoscaling / Cluster Autoscaler 2',
      ) +
      dashboard.withDescription('A dashboard that monitors Kubernetes and focuses on giving a overview for cluster autoscaler. It is created using the [Kubernetes / Autoscaling-mixin](https://github.com/adinhodovic/kubernetes-autoscaling-mixin).') +
      dashboard.withUid($._config.clusterAutoscalerDashboardUid) +
      dashboard.withTags($._config.tags + ['clsuter-autoscaler']) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(true) +
      dashboard.time.withFrom('now-24h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withLinks(
        [
          dashboard.link.dashboards.new('Kubernetes / Autoscaling / Cluster Autoscaler', $._config.tags + ['cluster-autoscaler']) +
          dashboard.link.link.options.withTargetBlank(true),
        ]
      ) +
      dashboard.withPanels(
        [
          caSummaryRow +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.makeGrid(
          [
            caTotalNodesStatPanel,
            caMaxNodesStatPanel,
            caNodeGroupsStatPanel,
            caHealthyNodesStatPanel,
            caSafeToScaleStatPanel,
            caNumberUnscheduledPodsStatPanel,
            caLastScaleDownStatPanel,
            caLastScaleUpStatPanel,
          ],
          panelWidth=3,
          panelHeight=3,
          startY=1
        ) +
        [
          caPodActivityTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(0) +
          timeSeriesPanel.gridPos.withY(4) +
          timeSeriesPanel.gridPos.withW(12) +
          timeSeriesPanel.gridPos.withH(8),
          caNodeActivityTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(12) +
          timeSeriesPanel.gridPos.withY(4) +
          timeSeriesPanel.gridPos.withW(12) +
          timeSeriesPanel.gridPos.withH(8),
          caAutoscalingActivityTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(0) +
          timeSeriesPanel.gridPos.withY(12) +
          timeSeriesPanel.gridPos.withW(24) +
          timeSeriesPanel.gridPos.withH(8),
        ]
      ) +
      if $._config.annotation.enabled then
        dashboard.withAnnotations($._config.customAnnotation)
      else {},
  }),
}
