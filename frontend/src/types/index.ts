export interface MonitoredTable {
  id: number
  project_id: string
  dataset_id: string
  table_id: string
  display_name: string | null
  is_active: boolean
  created_at: string | null
}

export interface MonitorConfig {
  id: number
  table_id: number
  monitor_type: 'freshness' | 'volume' | 'null_rate' | 'duplicate' | 'schema_drift'
  is_enabled: boolean
  config_json: string
  schedule_minutes: number
}

export interface MonitorRun {
  id: number
  monitor_config_id: number
  started_at: string | null
  completed_at: string | null
  status: 'pass' | 'warning' | 'fail' | 'error' | 'running'
  result_json: string | null
  error_message: string | null
}

export interface Alert {
  id: number
  table_id: number | null
  monitor_type: string
  severity: 'warning' | 'critical'
  message: string
  created_at: string | null
  is_acknowledged: boolean
  table_name: string | null
}

export interface DashboardStats {
  total_tables: number
  passing: number
  warning: number
  failing: number
  error: number
  unacknowledged_alerts: number
}

export interface TableMonitorStatus {
  config: MonitorConfig
  last_run: {
    status: string
    completed_at: string | null
    result_json: string | null
  } | null
}
