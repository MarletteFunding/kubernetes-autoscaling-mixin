local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;
local prometheus = g.query.prometheus;

local statPanel = g.panel.stat;
local timeSeriesPanel = g.panel.timeSeries;
local tablePanel = g.panel.table;

// Stat
local stOptions = statPanel.options;
local stStandardOptions = statPanel.standardOptions;
local stQueryOptions = statPanel.queryOptions;

// Timeseries
local tsOptions = timeSeriesPanel.options;
local tsStandardOptions = timeSeriesPanel.standardOptions;
local tsQueryOptions = timeSeriesPanel.queryOptions;
local tsFieldConfig = timeSeriesPanel.fieldConfig;
local tsCustom = tsFieldConfig.defaults.custom;
local tsLegend = tsOptions.legend;

// Table
local tbOptions = tablePanel.options;
local tbStandardOptions = tablePanel.standardOptions;
local tbQueryOptions = tablePanel.queryOptions;

{
  grafanaDashboards+:: {

    local datasourceVariable =
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source'),

    local jobVariable =
      query.new(
        'job',
        'label_values(kube_horizontalpodautoscaler_metadata_generation{}, job)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local namespaceVariable =
      query.new(
        'namespace',
        'label_values(kube_horizontalpodautoscaler_metadata_generation{job="$job"}, namespace)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Namespace') +
      query.selectionOptions.withMulti(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local hpaVariable =
      query.new(
        'hpa',
        'label_values(kube_horizontalpodautoscaler_spec_target_metric{job="$job", namespace="$namespace"},horizontalpodautoscaler)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Horitzontal Pod Autoscaler') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local metricNameVariable =
      query.new(
        'metric_name',
        'label_values(kube_horizontalpodautoscaler_spec_target_metric{job="$job", namespace="$namespace", horizontalpodautoscaler="$hpa"}, metric_name)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Metric Name') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local variables = [
      datasourceVariable,
      jobVariable,
      namespaceVariable,
      hpaVariable,
      metricNameVariable,
    ],

    local hpaDesiredReplicasQuery = |||
      round(
        sum(
          kube_horizontalpodautoscaler_status_desired_replicas{
            job="$job",
            namespace=~"$namespace",
            horizontalpodautoscaler="$hpa"
          }
        )
      )
    |||,

    local hpaDesiredReplicasStatPanel =
      statPanel.new(
        'Desired Replicas',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          hpaDesiredReplicasQuery,
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

    local hpaCurrentReplicasQuery = |||
      round(
        sum(
          kube_horizontalpodautoscaler_status_current_replicas{
            job="$job",
            namespace=~"$namespace",
            horizontalpodautoscaler="$hpa"
          }
        )
      )
    |||,

    local hpaCurrentReplicasStatPanel =
      statPanel.new(
        'Current Replicas',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          hpaCurrentReplicasQuery,
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

    local hpaMinReplicasQuery = |||
      round(
        sum(
          kube_horizontalpodautoscaler_spec_min_replicas{
            job="$job",
            namespace=~"$namespace",
            horizontalpodautoscaler="$hpa"
          }
        )
      )
    |||,

    local hpaMinReplicasStatPanel =
      statPanel.new(
        'Min Replicas',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          hpaMinReplicasQuery,
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

    local hpaMaxReplicasQuery = |||
      round(
        sum(
          kube_horizontalpodautoscaler_spec_max_replicas{
            job="$job",
            namespace=~"$namespace",
            horizontalpodautoscaler="$hpa"
          }
        )
      )
    |||,

    local hpaMaxReplicasStatPanel =
      statPanel.new(
        'Max Replicas',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          hpaMaxReplicasQuery,
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

    local hpaMetricTargetsQuery = |||
      round(
        sum(
          kube_horizontalpodautoscaler_spec_target_metric{
            job="$job",
            namespace=~"$namespace",
            horizontalpodautoscaler="$hpa",
            metric_name=~"$metric_name"
          }
        ) by (job, namespace, horizontalpodautoscaler, metric_name, metric_target_type)
      )
    |||,

    local hpaMetricTargetsTable =
      tablePanel.new(
        'Metric Targets'
      ) +
      tbStandardOptions.withUnit('short') +
      tbOptions.withSortBy(
        tbOptions.sortBy.withDisplayName('Horitzontal Pod Autoscaler')
      ) +
      tbQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            hpaMetricTargetsQuery,
          ) +
          prometheus.withFormat('table') +
          prometheus.withInstant(true),
        ]
      ) +
      tbQueryOptions.withTransformations([
        tbQueryOptions.transformation.withId(
          'merge'
        ),
        tbQueryOptions.transformation.withId(
          'organize'
        ) +
        tbQueryOptions.transformation.withOptions(
          {
            renameByName: {
              namespace: 'Namespace',
              horizontalpodautoscaler: 'Horitzontal Pod Autoscaler',
              metric_name: 'Metric Name',
              metric_target_type: 'Metric Target Type',
              'Value #A': 'Threshold',
            },
            indexByName: {
              namespace: 0,
              horizontalpodautoscaler: 1,
              metric_name: 2,
              metric_target_type: 3,
              'Value #A': 4,
            },
            excludeByName: {
              Time: true,
              job: true,
            },
          }
        ),
      ]),

    local hpaThresholdQuery = |||
      round(
        sum(
          kube_horizontalpodautoscaler_spec_target_metric{
            job="$job",
            namespace=~"$namespace",
            horizontalpodautoscaler="$hpa",
            metric_name=~"$metric_name",
            metric_target_type="utilization"
          }
        ) by (job, namespace, horizontalpodautoscaler, metric_name, metric_target_type)
      )
    |||,
    local hpaUtilizationQuery = std.strReplace(hpaThresholdQuery, 'spec_target_metric', 'status_target_metric'),

    local hpaUsageThresholdTimeSeriesPanel =
      timeSeriesPanel.new(
        'Usage & Threshold by Utilization',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            hpaUtilizationQuery,
          ) +
          prometheus.withLegendFormat(
            'Utilization / {{ metric_name }}'
          ),
          prometheus.new(
            '$datasource',
            hpaThresholdQuery,
          ) +
          prometheus.withLegendFormat(
            'Threshold / {{ metric_name }}'
          ),
        ]
      ) +
      tsStandardOptions.withUnit('short') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['lastNotNull', 'mean', 'max']) +
      tsLegend.withSortBy('Name') +
      tsLegend.withSortDesc(false) +
      tsCustom.withSpanNulls(false),

    local hpaReplicasTimeSeriesPanel =
      timeSeriesPanel.new(
        'Replicas',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            hpaDesiredReplicasQuery,
          ) +
          prometheus.withLegendFormat(
            'Desired Replicas'
          ),
          prometheus.new(
            '$datasource',
            hpaCurrentReplicasQuery,
          ) +
          prometheus.withLegendFormat(
            'Current Replicas'
          ),
          prometheus.new(
            '$datasource',
            hpaMinReplicasQuery,
          ) +
          prometheus.withLegendFormat(
            'Min Replicas'
          ),
          prometheus.new(
            '$datasource',
            hpaMaxReplicasQuery,
          ) +
          prometheus.withLegendFormat(
            'Max Replicas'
          ),
        ]
      ) +
      tsStandardOptions.withUnit('short') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['lastNotNull', 'mean', 'max']) +
      tsLegend.withSortBy('Name') +
      tsLegend.withSortDesc(false) +
      tsCustom.withSpanNulls(false),

    local hpaSummaryRow =
      row.new(
        title='Summary',
      ),

    'kubernetes-autoscaling-mixin-hpa.json':
      $._config.bypassDashboardValidation +
      dashboard.new(
        'Kubernetes / Autoscaling / Horitzontal Pod Autoscaling 2',
      ) +
      dashboard.withDescription('A dashboard that monitors Kubernetes HPAs which focuses on giving a overview for horizontal pod autoscalers. It is created using the [Kubernetes / Autoscaling-mixin](https://github.com/adinhodovic/kubernetes-autoscaling-mixin).') +
      dashboard.withUid($._config.hpaDashboardUid) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(true) +
      dashboard.time.withFrom('now-6h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withLinks(
        [
          dashboard.link.dashboards.new('Kubernetes / Autoscaling', $._config.tags) +
          dashboard.link.link.options.withTargetBlank(true),
        ]
      ) +
      dashboard.withPanels(
        [
          hpaSummaryRow +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.makeGrid(
          [
            hpaDesiredReplicasStatPanel,
            hpaCurrentReplicasStatPanel,
            hpaMinReplicasStatPanel,
            hpaMaxReplicasStatPanel,
          ],
          panelWidth=6,
          panelHeight=3,
          startY=1
        ) +
        [
          hpaMetricTargetsTable +
          tablePanel.gridPos.withX(0) +
          tablePanel.gridPos.withY(6) +
          tablePanel.gridPos.withW(24) +
          tablePanel.gridPos.withH(6),
          hpaUsageThresholdTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(0) +
          timeSeriesPanel.gridPos.withY(12) +
          timeSeriesPanel.gridPos.withW(24) +
          timeSeriesPanel.gridPos.withH(6),
          hpaReplicasTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(0) +
          timeSeriesPanel.gridPos.withY(18) +
          timeSeriesPanel.gridPos.withW(24) +
          timeSeriesPanel.gridPos.withH(6),
        ]
      ) +
      if $._config.annotation.enabled then
        dashboard.withAnnotations($._config.customAnnotation)
      else {},
  },
}
