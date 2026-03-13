import { useParams } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { getTableMonitors, runTableNow, getRunHistory } from '../api/client'
import MonitorCard from '../components/MonitorCard'
import VolumeChart from '../components/VolumeChart'
import { useTables } from '../hooks/useMonitors'
import { Play, ArrowLeft } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useState } from 'react'

export default function TableDetailPage() {
  const { tableId } = useParams<{ tableId: string }>()
  const id = Number(tableId)
  const qc = useQueryClient()
  const [running, setRunning] = useState(false)
  const { data: tables = [] } = useTables()
  const table = tables.find(t => t.id === id)
  const { data: monitors = [] } = useQuery({
    queryKey: ['table-monitors', id],
    queryFn: () => getTableMonitors(id),
    refetchInterval: 15000,
  })

  const volumeMonitor = monitors.find(m => m.config.monitor_type === 'volume')
  const { data: volumeHistory = [] } = useQuery({
    queryKey: ['run-history', volumeMonitor?.config.id],
    queryFn: () => getRunHistory(volumeMonitor!.config.id),
    enabled: !!volumeMonitor,
  })

  const volumeChartData = volumeHistory
    .filter((r: { result_json: string | null; completed_at: string | null }) => r.result_json)
    .map((r: { result_json: string; completed_at: string; status: string }) => {
      try {
        const parsed = JSON.parse(r.result_json)
        return { date: r.completed_at ? new Date(r.completed_at).toLocaleDateString() : '', value: parsed.value || 0, status: r.status }
      } catch { return null }
    })
    .filter(Boolean)
    .reverse()

  const handleRunNow = async () => {
    setRunning(true)
    await runTableNow(id)
    setTimeout(() => {
      qc.invalidateQueries({ queryKey: ['table-monitors', id] })
      setRunning(false)
    }, 3000)
  }

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <div className="flex items-center gap-3">
        <Link to="/" className="text-gray-500 hover:text-white"><ArrowLeft size={20} /></Link>
        <div className="flex-1">
          <h1 className="text-xl font-bold text-white">
            {table?.display_name || `${table?.dataset_id}.${table?.table_id}`}
          </h1>
          <p className="text-xs text-gray-500">{table?.project_id}</p>
        </div>
        <button onClick={handleRunNow} disabled={running}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50">
          <Play size={14} /> {running ? 'Running...' : 'Run Now'}
        </button>
      </div>

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
        {monitors.map(m => (
          <MonitorCard key={m.config.id} monitor={m} />
        ))}
      </div>

      {volumeChartData.length > 0 && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <h3 className="text-sm font-medium text-gray-300 mb-4">Volume History</h3>
          <VolumeChart data={volumeChartData} />
        </div>
      )}
    </div>
  )
}
