import { Alert } from '../types'
import StatusBadge from './StatusBadge'
import { acknowledgeAlert } from '../api/client'
import { useQueryClient } from '@tanstack/react-query'

interface Props { alerts: Alert[] }

export default function AlertFeed({ alerts }: Props) {
  const qc = useQueryClient()
  const ack = async (id: number) => {
    await acknowledgeAlert(id)
    qc.invalidateQueries({ queryKey: ['alerts'] })
    qc.invalidateQueries({ queryKey: ['dashboard'] })
  }

  if (!alerts.length) return <div className="text-center text-gray-500 py-12">No alerts</div>

  return (
    <div className="space-y-3">
      {alerts.map(alert => (
        <div key={alert.id} className={`bg-gray-900 border rounded-xl p-4 flex items-start gap-4 ${alert.is_acknowledged ? 'border-gray-800 opacity-60' : 'border-gray-700'}`}>
          <StatusBadge status={alert.severity} size="md" />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-sm font-medium text-gray-200">{alert.table_name}</span>
              <span className="text-xs text-gray-500 bg-gray-800 px-2 py-0.5 rounded">{alert.monitor_type}</span>
            </div>
            <p className="text-sm text-gray-400">{alert.message}</p>
            {alert.created_at && (
              <p className="text-xs text-gray-600 mt-1">{new Date(alert.created_at).toLocaleString()}</p>
            )}
          </div>
          {!alert.is_acknowledged && (
            <button onClick={() => ack(alert.id)} className="text-xs text-blue-400 hover:text-blue-300 whitespace-nowrap">
              Acknowledge
            </button>
          )}
        </div>
      ))}
    </div>
  )
}
