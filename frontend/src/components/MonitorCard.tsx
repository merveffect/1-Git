import StatusBadge from './StatusBadge'
import { TableMonitorStatus } from '../types'
import { Clock, BarChart2, AlertTriangle, Copy, GitBranch, FlaskConical } from 'lucide-react'

const icons: Record<string, JSX.Element> = {
  freshness: <Clock size={16} />,
  volume: <BarChart2 size={16} />,
  null_rate: <AlertTriangle size={16} />,
  duplicate: <Copy size={16} />,
  schema_drift: <GitBranch size={16} />,
  dbt_tests: <FlaskConical size={16} />,
}

const labels: Record<string, string> = {
  freshness: 'Freshness',
  volume: 'Volume',
  null_rate: 'Null Rate',
  duplicate: 'Duplicates',
  schema_drift: 'Schema Drift',
  dbt_tests: 'dbt Tests',
}

interface Props { monitor: TableMonitorStatus }

export default function MonitorCard({ monitor }: Props) {
  const { config, last_run } = monitor
  const status = last_run?.status || 'no data'
  let message = 'No runs yet'
  if (last_run?.result_json) {
    try { message = JSON.parse(last_run.result_json).message || message } catch {}
  }

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 text-gray-300">
          {icons[config.monitor_type]}
          <span className="font-medium text-sm">{labels[config.monitor_type]}</span>
        </div>
        <StatusBadge status={status} />
      </div>
      <p className="text-xs text-gray-500 leading-relaxed">{message}</p>
      {last_run?.completed_at && (
        <p className="text-xs text-gray-600">
          Last checked: {new Date(last_run.completed_at).toLocaleString()}
        </p>
      )}
    </div>
  )
}
