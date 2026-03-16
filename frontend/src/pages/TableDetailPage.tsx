import { useParams, Link } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { getTableMonitors, runTableNow, getAllMonitorHistory } from '../api/client'
import MonitorCard from '../components/MonitorCard'
import VolumeChart from '../components/VolumeChart'
import LineageGraph from '../components/LineageGraph'
import DbtTestsDetail from '../components/DbtTestsDetail'
import UpdateTimeline from '../components/UpdateTimeline'
import { useTables } from '../hooks/useMonitors'
import { Play, ArrowLeft, Clock, BarChart2, AlertTriangle, Copy, GitBranch, FlaskConical } from 'lucide-react'
import { useState } from 'react'

const MONITOR_LABELS: Record<string, string> = {
  freshness: 'Freshness History',
  volume: 'Volume History',
  null_rate: 'Null Rate History',
  duplicate: 'Duplicate Rate History',
  schema_drift: 'Schema Drift History',
  dbt_tests: 'dbt Test History',
}

const MONITOR_ICONS: Record<string, JSX.Element> = {
  freshness: <Clock size={14} />,
  volume: <BarChart2 size={14} />,
  null_rate: <AlertTriangle size={14} />,
  duplicate: <Copy size={14} />,
  schema_drift: <GitBranch size={14} />,
  dbt_tests: <FlaskConical size={14} />,
}

const STATUS_COLOR: Record<string, string> = {
  pass: 'bg-green-500',
  warning: 'bg-yellow-400',
  fail: 'bg-red-500',
  error: 'bg-gray-500',
}

interface RunEntry {
  status: string
  completed_at: string | null
  value: number | null
  message: string | null
}

function MonitorHistoryRow({ type, runs }: { type: string; runs: RunEntry[] }) {
  if (!runs || runs.length === 0) return null
  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
      <div className="flex items-center gap-2 mb-3">
        <span className="text-gray-400">{MONITOR_ICONS[type]}</span>
        <h3 className="text-sm font-medium text-gray-300">{MONITOR_LABELS[type] || type}</h3>
        <span className="ml-auto text-xs text-gray-600">{runs.length} runs</span>
      </div>

      {/* Dot timeline */}
      <div className="flex items-center gap-1.5 flex-wrap mb-3">
        {[...runs].reverse().map((run, i) => (
          <div key={i} className="relative group">
            <div className={`w-4 h-4 rounded-full ${STATUS_COLOR[run.status] || 'bg-gray-700'} cursor-default`} />
            <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-10 hidden group-hover:block bg-gray-800 border border-gray-700 text-xs text-gray-200 rounded-lg px-2 py-1.5 whitespace-nowrap shadow-xl pointer-events-none min-w-max">
              <p className="font-medium">{run.completed_at ? new Date(run.completed_at).toLocaleString() : '—'}</p>
              {run.message && <p className="text-gray-400 mt-0.5">{run.message}</p>}
              {run.value != null && <p className="text-gray-400">Value: {typeof run.value === 'number' ? run.value.toLocaleString() : run.value}</p>}
            </div>
          </div>
        ))}
      </div>

      {/* Value chart for numeric monitors — one point per day (latest run) */}
      {(type === 'volume' || type === 'freshness') && runs.some(r => r.value != null) && (() => {
        // Deduplicate: keep only the latest run per calendar day
        const byDay = new Map<string, { date: string; value: number; status: string }>()
        for (const r of runs) {
          if (r.value == null || !r.completed_at) continue
          const day = new Date(r.completed_at).toLocaleDateString()
          // runs are sorted asc, so later ones overwrite earlier ones for the same day
          byDay.set(day, { date: day, value: r.value as number, status: r.status })
        }
        const chartData = Array.from(byDay.values())
        return chartData.length > 0 ? <VolumeChart data={chartData} /> : null
      })()}
    </div>
  )
}

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

  const { data: allHistory = {} } = useQuery<Record<string, RunEntry[]>>({
    queryKey: ['all-monitor-history', id],
    queryFn: () => getAllMonitorHistory(id),
    refetchInterval: 30000,
  })

  const handleRunNow = async () => {
    setRunning(true)
    await runTableNow(id)
    setTimeout(() => {
      qc.invalidateQueries({ queryKey: ['table-monitors', id] })
      qc.invalidateQueries({ queryKey: ['all-monitor-history', id] })
      setRunning(false)
    }, 3000)
  }

  const monitorTypesWithHistory = Object.keys(allHistory).filter(t => allHistory[t]?.length > 0)

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

      {/* Current status cards */}
      <div>
        <h2 className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-3">Current Status</h2>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          {monitors.map(m => (
            <MonitorCard key={m.config.id} monitor={m} tableId={id} />
          ))}
        </div>
      </div>

      {/* Per-monitor history */}
      {monitorTypesWithHistory.length > 0 && (
        <div>
          <h2 className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-3">Run History</h2>
          <div className="space-y-4">
            {monitorTypesWithHistory.map(type => (
              <MonitorHistoryRow key={type} type={type} runs={allHistory[type]} />
            ))}
          </div>
        </div>
      )}

      {monitorTypesWithHistory.length === 0 && monitors.length > 0 && (
        <div className="text-center py-8 text-gray-600 text-sm">
          No run history yet — click <strong className="text-gray-400">Run Now</strong> to trigger the first check.
        </div>
      )}

      {/* dbt Test Details */}
      {table && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <h2 className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-4">
            dbt Test Details
          </h2>
          <DbtTestsDetail modelName={table.table_id} />
        </div>
      )}

      {/* Update history timeline */}
      {table && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <h2 className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-4">
            Update History
          </h2>
          <UpdateTimeline tableId={id} />
        </div>
      )}

      {/* Lineage graph — only shown when dbt project is configured */}
      {table && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <h2 className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-4">
            Lineage Graph
          </h2>
          <LineageGraph modelName={table.table_id} />
        </div>
      )}
    </div>
  )
}
