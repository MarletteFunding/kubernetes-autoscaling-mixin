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
local tablePanel = g.panel.table;
local pieChartPanel = g.panel.pieChart;

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

// Table
local tbOptions = tablePanel.options;
local tbStandardOptions = tablePanel.standardOptions;
local tbQueryOptions = tablePanel.queryOptions;
local tbFieldConfig = tablePanel.fieldConfig;
local tbOverride = tbStandardOptions.override;

// Pie Chart
local pieOptions = pieChartPanel.options;
local pieStandardOptions = pieChartPanel.standardOptions;
local pieQueryOptions = pieChartPanel.queryOptions;

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
        'label_values(karpenter_nodes_allocatable{}, job)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local nodePoolVariable =
      query.new(
        'nodepool',
        'label_values(karpenter_nodepools_allowed_disruptions{job="$job"}, nodepool)'
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Node Pool') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local variables = [
      datasourceVariable,
      jobVariable,
      nodePoolVariable,
    ],

    local karpenterNodeTerminationP50DurationQuery = |||
      max(
        karpenter_nodes_termination_duration_seconds{
          job=~"$job",
          quantile="0.5"
        }
      )
    |||,
    local karpenterNodeTerminationP95DurationQuery = std.strReplace(karpenterNodeTerminationP50DurationQuery, '0.5', '0.95'),
    local karpenterNodeTerminationP99DurationQuery = std.strReplace(karpenterNodeTerminationP50DurationQuery, '0.5', '0.99'),

    local karpenterNodeTerminationDurationTimeSeriesPanel =
      timeSeriesPanel.new(
        title='Node Termination Duration',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            karpenterNodeTerminationP50DurationQuery,
          ) +
          prometheus.withLegendFormat(
            'P50'
          ) +
          prometheus.withInterval('1m'),
          prometheus.new(
            '$datasource',
            karpenterNodeTerminationP95DurationQuery,
          ) +
          prometheus.withLegendFormat(
            'P95'
          ) +
          prometheus.withInterval('1m'),
          prometheus.new(
            '$datasource',
            karpenterNodeTerminationP99DurationQuery,
          ) +
          prometheus.withLegendFormat(
            'P99'
          ) +
          prometheus.withInterval('1m'),
        ]
      ) +
      tsStandardOptions.withUnit('s') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['lastNotNull', 'mean', 'max']) +
      tsLegend.withSortBy('Mean') +
      tsLegend.withSortDesc(true) +
      tsCustom.withSpanNulls(false),

    local karpenterNodePerformanceRow =
      row.new(
        title='Node Performance',
      ),

    local karpenterPodActivityRow =
      row.new(
        title='Pod Activity',
      ),

    'kubernetes-autoscaling-mixin-karpenter-perf.json': if $._config.karpenter.enabled then
      $._config.bypassDashboardValidation +
      dashboard.new(
        'Kubernetes / Autoscaling / Karpenter / Performance',
      ) +
      dashboard.withDescription('A dashboard that monitors Karpenter and focuses on Karpenter performance. It is created using the [Kubernetes Autoscaling-mixin](https://github.com/adinhodovic/kubernetes-autoscaling-mixin).') +
      dashboard.withUid($._config.karpenterPerformanceDashboardUid) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(true) +
      dashboard.time.withFrom('now-24h') +
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
          karpenterNodePerformanceRow +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.makeGrid(
          [
            karpenterNodeTerminationDurationTimeSeriesPanel,
          ],
          panelWidth=12,
          panelHeight=6,
          startY=1
        )
      ) +
      if $._config.annotation.enabled then
        dashboard.withAnnotations($._config.customAnnotation)
      else {},
  }),
}
