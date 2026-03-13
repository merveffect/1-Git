import { useAlerts } from '../hooks/useAlerts'
import AlertFeed from '../components/AlertFeed'
import { useState } from 'react'

export default function AlertsPage() {
  const [showAcknowledged, setShowAcknowledged] = useState(false)
  const { data: alerts = [], isLoading } = useAlerts({ acknowledged: showAcknowledged || undefined, limit: 100 })

  return (
    <div className="max-w-3xl mx-auto space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Alerts</h1>
          <p className="text-gray-500 text-sm mt-0.5">Anomalies and threshold violations</p>
        </div>
        <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
          <input type="checkbox" checked={showAcknowledged} onChange={e => setShowAcknowledged(e.target.checked)}
            className="rounded border-gray-600 bg-gray-800" />
          Show acknowledged
        </label>
      </div>
      {isLoading ? <div className="text-gray-500 text-sm">Loading...</div> : <AlertFeed alerts={alerts} />}
    </div>
  )
}
