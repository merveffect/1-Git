import { useState } from 'react'
import StatusBadge from './StatusBadge'
import DuplicateConfigModal from './DuplicateConfigModal'
import { TableMonitorStatus } from '../types'
import { Clock, BarChart2, AlertTriangle, Copy, GitBranch, FlaskConical, Settings2 } from 'lucide-react'

const icons: Record<string, JSX.Element> = {
  freshness:    <Clock size={16} />,
  volume:       <BarChart2 size={16} />,
  null_rate:    <AlertTriangle size={16} />,
  duplicate:    <Copy size={16} />,
  schema_drift: <GitBranch size={16} />,
  dbt_tests:    <FlaskConical size={16} />,
}

const labels: Record<string, string> = {
  freshness:    'Freshness',
  volume:       'Volume',
  null_rate:    'Null Rate',
  duplicate:    'Duplicates',
  schema_drift: 'Schema Drift',
  dbt_tests:    'dbt Tests',
}

interface Props {
  monitor: TableMonitorStatus
  tableId?: number
}

export default function MonitorCard({ monitor, tableId }: Props) {
  const { config, last_run } = monitor
  const [showConfig, setShowConfig] = useState(false)
  const status = last_run?.status || 'no_data'

  let message = 'No runs yet'
  if (last_run?.result_json) {
    try { message = JSON.parse(last_run.result_json).message || message } catch {}
  }

  const isDuplicateUnconfigured =
    config.monitor_type === 'duplicate' &&
    !(JSON.parse(config.config_json || '{}').key_columns?.length)

  return (
    <>
      <div className={`bg-gray-900 border rounded-xl p-4 flex flex-col gap-2 ${
        isDuplicateUnconfigured ? 'border-yellow-500/40' : 'border-gray-800'
      }`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-gray-300">
            {icons[config.monitor_type]}
            <span className="font-medium text-sm">{labels[config.monitor_type]}</span>
          </div>
          <div className="flex items-center gap-2">
            {config.monitor_type === 'duplicate' && (
              <button
                onClick={() => setShowConfig(true)}
                className="text-gray-500 hover:text-gray-300 transition-colors"
                title="Configure key columns"
              >
                <Settings2 size={14} />
              </button>
            )}
            <StatusBadge status={status} />
          </div>
        </div>

        <p className="text-xs text-gray-500 leading-relaxed">{message}</p>

        {isDuplicateUnconfigured && (
          <button
            onClick={() => setShowConfig(true)}
            className="text-xs text-yellow-400 hover:text-yellow-300 text-left flex items-center gap-1 mt-0.5"
          >
            <Settings2 size={11} /> Configure key columns →
          </button>
        )}

        {last_run?.completed_at && (
          <p className="text-xs text-gray-600">
            Last checked: {new Date(last_run.completed_at).toLocaleString()}
          </p>
        )}
      </div>

      {showConfig && tableId && (
        <DuplicateConfigModal
          monitor={monitor}
          tableId={tableId}
          onClose={() => setShowConfig(false)}
        />
      )}
    </>
  )
}
