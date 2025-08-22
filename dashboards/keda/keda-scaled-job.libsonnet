local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;
local prometheus = g.query.prometheus;

local timeSeries = g.panel.timeSeries;
local tablePanel = g.panel.table;

// Timeseries
local tsOptions = timeSeries.options;
local tsStandardOptions = timeSeries.standardOptions;
local tsQueryOptions = timeSeries.queryOptions;
local tsFieldConfig = timeSeries.fieldConfig;
local tsCustom = tsFieldConfig.defaults.custom;
local tsLegend = tsOptions.legend;

// Table
local tbOptions = tablePanel.options;
local tbStandardOptions = tablePanel.standardOptions;
local tbQueryOptions = tablePanel.queryOptions;
local tbPanelOptions = tablePanel.panelOptions;

{
  local timeSeriesPanel(title, unit, query, legend, calcs=['mean', 'max'], stack='none') =
    timeSeries.new(title) +
    tsQueryOptions.withTargets(
      prometheus.new(
        '$datasource',
        query,
      ) +
      prometheus.withLegendFormat(
        legend
      )
    ) +
    tsStandardOptions.withUnit(unit) +
    tsOptions.tooltip.withMode('multi') +
    tsOptions.tooltip.withSort('desc') +
    tsLegend.withShowLegend() +
    tsLegend.withDisplayMode('table') +
    tsLegend.withPlacement('right') +
    tsLegend.withCalcs(calcs) +
    tsLegend.withSortBy('Mean') +
    tsLegend.withSortDesc(true) +
    (
      if stack == 'normal' then
        tsCustom.withFillOpacity(100) +
        tsCustom.stacking.withMode(stack) +
        tsCustom.withLineWidth(0)
      else {}
    ),

  grafanaDashboards+:: std.prune({

    local datasourceVariable =
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source') +
      {
        current: {
          selected: true,
          text: $._config.datasourceName,
          value: $._config.datasourceName,
        },
      },

    local clusterVariable =
      query.new(
        $._config.clusterLabel,
        'label_values(keda_scaled_job_errors_total{}, cluster)' % $._config,
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if $._config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    local jobVariable =
      query.new(
        'job',
        'label_values(keda_scaled_job_errors_total{%(clusterLabel)s="$cluster"}, job)' % $._config,
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local operatorNamespaceVariable =
      query.new(
        'operator_namespace',
        'label_values(keda_scaled_job_errors_total{%(clusterLabel)s="$cluster", job=~"$job"}, namespace)' % $._config
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Operator Namespace') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local resourceNamespaceVariable =
      query.new(
        'resource_namespace',
        'label_values(keda_scaled_job_errors_total{%(clusterLabel)s="$cluster", job=~"$job", namespace=~"$operator_namespace"}, exported_namespace)' % $._config
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Resource Namespace') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local scaledJobVariable =
      query.new(
        'scaled_job',
        'label_values(keda_scaled_job_errors_total{%(clusterLabel)s="$cluster", job=~"$job", namespace=~"$operator_namespace", exported_namespace=~"$resource_namespace"}, scaledJob)' % $._config
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Scaled Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local scalerVariable =
      query.new(
        'scaler',
        'label_values(keda_scaler_active{%(clusterLabel)s="$cluster", job=~"$job", namespace=~"$operator_namespace", exported_namespace="$resource_namespace", type="scaledjob", scaledObject="$scaled_job"}, scaler)' % $._config
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Scaler') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local metricVariable =
      query.new(
        'metric',
        'label_values(keda_scaler_active{%(clusterLabel)s="$cluster", job=~"$job", namespace=~"$operator_namespace", exported_namespace="$resource_namespace", type="scaledjob", scaledObject=~"$scaled_job", scaler=~"$scaler"}, metric)' % $._config
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Metric') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local variables = [
      datasourceVariable,
      clusterVariable,
      jobVariable,
      operatorNamespaceVariable,
      resourceNamespaceVariable,
      scaledJobVariable,
      scalerVariable,
      metricVariable,
    ],

    local queries = {
      resourcesRegisteredByNamespaceQuery: |||
        sum(
          keda_resource_registered_total{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            namespace=~"$operator_namespace",
            type="scaled_job"
          }
        ) by (exported_namespace, type)
      ||| % $._config,

      triggersByTypeQuery: |||
        sum(
          keda_trigger_registered_total{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            namespace=~"$operator_namespace",
          }
        ) by (type)
      ||| % $._config,

      scaledJobsErrorsTotalQuery: |||
        sum(
          increase(
            keda_scaled_job_errors_total{
              %(clusterLabel)s="$cluster",
              job=~"$job",
              namespace=~"$operator_namespace",
              exported_namespace=~"$resource_namespace",
            }[$__rate_interval]
          )
        ) by (exported_namespace, scaledJob)
      ||| % $._config,

      scalerDetailErrorsTotalQuery: |||
        sum(
          increase(
            keda_scaler_detail_errors_total{
              %(clusterLabel)s="$cluster",
              job=~"$job",
              namespace=~"$operator_namespace",
              exported_namespace=~"$resource_namespace",
              type="scaledjob"
            }[$__rate_interval]
          )
        ) by (exported_namespace, scaledObject, scaler)
      ||| % $._config,

      scaleTargetValuesQuery: |||
        sum(
          keda_scaler_metrics_value{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            namespace=~"$operator_namespace",
            exported_namespace=~"$resource_namespace",
            type="scaledjob"
          }
        ) by (job, exported_namespace, scaledObject, scaler, metric)
      ||| % $._config,

      scaledJobActiveQuery: |||
        sum(
          keda_scaler_active{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            namespace="$operator_namespace",
            exported_namespace="$resource_namespace",
            type="scaledjob",
            scaledObject="$scaled_job"
          }
        ) by (exported_namespace, scaledObject)
      ||| % $._config,

      scaledJobDetailErrorTotalQuery: |||
        sum(
          increase(
            keda_scaler_detail_errors_total{
              %(clusterLabel)s="$cluster",
              job=~"$job",
              namespace="$operator_namespace",
              exported_namespace="$resource_namespace",
              type="scaledjob",
              scaledObject="$scaled_job"
            }[$__rate_interval]
          )
        ) by (exported_namespace, scaledObject)
      ||| % $._config,

      scaledJobMetricValueQuery: |||
        avg(
          keda_scaler_metrics_value{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            namespace="$operator_namespace",
            exported_namespace="$resource_namespace",
            type="scaledjob",
            scaledObject="$scaled_job",
            scaler="$scaler",
            metric="$metric"
          }
        ) by (exported_namespace, scaledObject, scaler, metric)
      ||| % $._config,

      scaledJobMetricLatencyQuery: |||
        avg(
          keda_scaler_metrics_latency_seconds{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            namespace="$operator_namespace",
            exported_namespace="$resource_namespace",
            type="scaledjob",
            scaledObject="$scaled_job",
            scaler="$scaler",
            metric="$metric"
          }
        ) by (exported_namespace, scaledObject, scaler, metric)
      ||| % $._config,
    },

    local panels = {
      resourcesRegisteredByNamespaceTimeSeries: timeSeriesPanel(
        'Resources Registered by Namespace',
        'short',
        queries.resourcesRegisteredByNamespaceQuery,
        '{{ exported_namespace }}/{{ type }}',
        stack='normal',
      ),

      triggersByTypeTimeSeries: timeSeriesPanel(
        'Triggers by Type',
        'short',
        queries.triggersByTypeQuery,
        '{{ type }}',
        stack='normal',
      ),

      scaledTargetValuesTable:
        tablePanel.new(
          'Scale Target Values',
        ) +
        tbPanelOptions.withDescription('This table has links to the Workload dashboard for the scaled Job, which can be used to see the current resource usage. The Workload dashboard can be found at [kubernetes-mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin) and requires ID customization.') +
        tbStandardOptions.withUnit('short') +
        tbOptions.withSortBy(
          tbOptions.sortBy.withDisplayName('Scaled Object') +
          tbOptions.sortBy.withDesc(true)
        ) +
        tbOptions.footer.withEnablePagination(true) +
        tbQueryOptions.withTargets(
          [
            prometheus.new(
              '$datasource',
              queries.scaleTargetValuesQuery,
            ) +
            prometheus.withFormat('table') +
            prometheus.withInstant(true),
          ]
        ) +
        tbQueryOptions.withTransformations([
          tbQueryOptions.transformation.withId(
            'organize'
          ) +
          tbQueryOptions.transformation.withOptions(
            {
              renameByName: {
                scaledObject: 'Scaled Object',
                exported_namespace: 'Resource Namespace',
                scaler: 'Scaler',
                metric: 'Metric',
                value: 'Value',
              },
              indexByName: {
                scaledObject: 0,
                exported_namespace: 1,
                scaler: 2,
                metric: 3,
                value: 4,
              },
              excludeByName: {
                Time: true,
                job: true,
              },
            }
          ),
        ]) +
        tbStandardOptions.withLinks([
          tbPanelOptions.link.withTitle('Go to HPA') +
          tbPanelOptions.link.withUrl(
            '/d/%s/kubernetes-compute-resources-workload?var-namespace=${__data.fields.exported_namespace}&var-type=ScaledJob&var-workload=${__data.fields.scaledObject}' % $._config.keda.k8sResourcesWorkloadDashboardUid
          ) +
          tbPanelOptions.link.withTargetBlank(true),
        ]),

      scalerDetailErrorsTotalTimeSeries: timeSeriesPanel(
        'Scaler Detail Errors',
        'short',
        queries.scalerDetailErrorsTotalQuery,
        '{{ scaledObject }} / {{ scaler }}',
      ),

      scaledJobsErrorsTimeSeries: timeSeriesPanel(
        'Scaled Jobs Errors',
        'short',
        queries.scaledJobsErrorsTotalQuery,
        '{{ scaledJob }}',
      ),

      scaledJobActiveQuery: timeSeriesPanel(
        'Scaled Job Active',
        'short',
        queries.scaledJobActiveQuery,
        '{{ scaledObject }}',
      ),

      scaledJobDetailErrorTotalQuery: timeSeriesPanel(
        'Scaled Job Detail Errors',
        'short',
        queries.scaledJobDetailErrorTotalQuery,
        '{{ scaledObject }}',
      ),

      scaledJobMetricValueQuery: timeSeriesPanel(
        'Scaled Job Metric Value',
        'short',
        queries.scaledJobMetricValueQuery,
        '{{ scaledObject }} / {{ scaler }} / {{ metric }}',
        stack='normal',
      ),

      scaledJobMetricLatencyQuery: timeSeriesPanel(
        'Scaled Job Metric Latency',
        's',
        queries.scaledJobMetricLatencyQuery,
        '{{ scaledObject }} / {{ scaler }} / {{ metric }}',
      ),
    },

    local rows =
      [
        row.new('Summary') +
        row.gridPos.withX(0) +
        row.gridPos.withY(0) +
        row.gridPos.withW(24) +
        row.gridPos.withH(1),
      ] +
      grid.wrapPanels(
        [
          panels.resourcesRegisteredByNamespaceTimeSeries,
          panels.triggersByTypeTimeSeries,
        ],
        panelWidth=12,
        panelHeight=6,
        startY=1,
      ) +
      grid.wrapPanels(
        [
          panels.scaledJobsErrorsTimeSeries,
          panels.scalerDetailErrorsTotalTimeSeries,
        ],
        panelWidth=12,
        panelHeight=6,
        startY=7,
      ) +
      grid.wrapPanels(
        [
          panels.scaledTargetValuesTable,
        ],
        panelWidth=24,
        panelHeight=8,
        startY=13,
      ) +
      [
        row.new('Scaled Job $scaled_job / $scaler / $metric') +
        row.gridPos.withX(0) +
        row.gridPos.withY(21) +
        row.gridPos.withW(24) +
        row.gridPos.withH(1),
      ] +
      grid.wrapPanels(
        [
          panels.scaledJobActiveQuery,
          panels.scaledJobDetailErrorTotalQuery,
        ],
        panelWidth=12,
        panelHeight=4,
        startY=22,
      ) +
      grid.wrapPanels(
        [
          panels.scaledJobMetricValueQuery,
          panels.scaledJobMetricLatencyQuery,
        ],
        panelWidth=24,
        panelHeight=8,
        startY=26,
      ),

    'kubernetes-autoscaling-mixin-keda-sj.json': if $._config.keda.enabled then
      $._config.bypassDashboardValidation +
      dashboard.new(
        'Kubernetes / Autoscaling / Keda / Scaled Job',
      ) +
      dashboard.withDescription('A dashboard that monitors Keda and focuses on giving a overview for Scaled Jobs. It is created using the [kubernetes-autoscaling-mixin](https://github.com/adinhodovic/kubernetes-autoscaling-mixin).') +
      dashboard.withUid($._config.kedaScaledJobDashboardUid) +
      dashboard.withTags($._config.tags + ['keda']) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(true) +
      dashboard.time.withFrom('now-24h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withLinks(
        [
          dashboard.link.dashboards.new('Kubernetes / Autoscaling', $._config.tags) +
          dashboard.link.link.options.withTargetBlank(true) +
          dashboard.link.link.options.withAsDropdown(true) +
          dashboard.link.link.options.withIncludeVars(true) +
          dashboard.link.link.options.withKeepTime(true),
        ]
      ) +
      dashboard.withPanels(
        rows
      ) +
      if $._config.annotation.enabled then
        dashboard.withAnnotations($._config.customAnnotation)
      else {},
  }) + if $._config.keda.enabled then {
    'kubernetes-autoscaling-mixin-keda-sj.json'+: $._config.bypassDashboardValidation,
  }
  else {},
}
