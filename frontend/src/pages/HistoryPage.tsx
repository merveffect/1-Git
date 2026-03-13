import { useQuery } from '@tanstack/react-query'
import { getAllRuns } from '../api/client'
import { Link } from 'react-router-dom'
import { useState } from 'react'
import { useTables } from '../hooks/useMonitors'

interface Run {
  run_id: number
  table_id: number
  table_name: string
  monitor_type: string
  status: string
  completed_at: string | null
  message: string | null
}

const MONITOR_TYPES = ['freshness', 'volume', 'null_rate', 'duplicate', 'schema_drift', 'dbt_tests']
const MONITOR_LABELS: Record<string, string> = {
  freshness: 'Freshness',
  volume: 'Volume',
  null_rate: 'Null Rate',
  duplicate: 'Duplicates',
  schema_drift: 'Schema',
  dbt_tests: 'dbt Tests',
}

const STATUS_COLOR: Record<string, string> = {
  pass: 'bg-green-500',
  warning: 'bg-yellow-400',
  fail: 'bg-red-500',
  error: 'bg-gray-500',
  no_data: 'bg-gray-800',
}

const STATUS_RING: Record<string, string> = {
  pass: 'ring-green-500/40',
  warning: 'ring-yellow-400/40',
  fail: 'ring-red-500/40',
  error: 'ring-gray-500/40',
}

function StatusDot({ status, tooltip }: { status: string; tooltip: string }) {
  return (
    <div className="relative group flex items-center justify-center">
      <div className={`w-3 h-3 rounded-full ${STATUS_COLOR[status] || STATUS_COLOR.no_data}`} />
      {/* Tooltip */}
      <div className="absolute bottom-5 left-1/2 -translate-x-1/2 z-10 hidden group-hover:block bg-gray-800 border border-gray-700 text-xs text-gray-200 rounded-lg px-2 py-1 whitespace-nowrap shadow-xl pointer-events-none">
        {tooltip}
      </div>
    </div>
  )
}

export default function HistoryPage() {
  const [filterStatus, setFilterStatus] = useState<string>('all')
  const { data: tables = [] } = useTables()
  const { data: allRuns = [], isLoading } = useQuery<Run[]>({
    queryKey: ['all-runs'],
    queryFn: () => getAllRuns(500),
    refetchInterval: 30000,
  })

  // Build heatmap: tableId -> monitorType -> last N runs (up to 10)
  const heatmap: Record<number, Record<string, Run[]>> = {}
  for (const run of allRuns) {
    if (!heatmap[run.table_id]) heatmap[run.table_id] = {}
    if (!heatmap[run.table_id][run.monitor_type]) heatmap[run.table_id][run.monitor_type] = []
    if (heatmap[run.table_id][run.monitor_type].length < 10) {
      heatmap[run.table_id][run.monitor_type].push(run)
    }
  }

  // Current status per table (worst across monitor types)
  const priority: Record<string, number> = { fail: 3, error: 2, warning: 1, pass: 0 }
  const tableStatus: Record<number, string> = {}
  for (const [tid, monitors] of Object.entries(heatmap)) {
    let worst = 'no_data'
    for (const runs of Object.values(monitors)) {
      const latest = runs[0]?.status
      if (latest && (worst === 'no_data' || (priority[latest] ?? -1) > (priority[worst] ?? -1))) {
        worst = latest
      }
    }
    tableStatus[Number(tid)] = worst
  }

  const filteredTables = tables.filter(t => {
    if (filterStatus === 'all') return true
    return tableStatus[t.id] === filterStatus
  })

  // Recent activity feed (across all pipelines, sorted by time)
  const recentActivity = [...allRuns]
    .filter(r => r.status !== 'pass')
    .sort((a, b) => (b.completed_at ?? '').localeCompare(a.completed_at ?? ''))
    .slice(0, 20)

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Pipeline History</h1>
        <p className="text-gray-500 text-sm mt-0.5">Historical health across all monitored pipelines</p>
      </div>

      {/* Filter bar */}
      <div className="flex items-center gap-2">
        {(['all', 'pass', 'warning', 'fail', 'error'] as const).map(s => (
          <button
            key={s}
            onClick={() => setFilterStatus(s)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
              filterStatus === s
                ? 'bg-blue-600 text-white'
                : 'bg-gray-800 text-gray-400 hover:text-white'
            }`}
          >
            {s === 'all' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}
          </button>
        ))}
      </div>

      {/* Heatmap grid */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-800">
                <th className="text-left text-xs text-gray-500 font-medium px-4 py-3 w-56">Pipeline</th>
                <th className="text-xs text-gray-500 font-medium px-2 py-3 text-center" colSpan={6}>
                  Monitor Type → each dot = one run (newest left)
                </th>
              </tr>
              <tr className="border-b border-gray-800 bg-gray-950">
                <th className="px-4 py-2" />
                {MONITOR_TYPES.map(type => (
                  <th key={type} className="text-xs text-gray-500 font-medium px-3 py-2 text-center whitespace-nowrap">
                    {MONITOR_LABELS[type]}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="text-center text-gray-500 text-sm py-10">Loading history...</td>
                </tr>
              ) : filteredTables.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center text-gray-500 text-sm py-10">
                    No pipelines yet. Add tables from the Dashboard.
                  </td>
                </tr>
              ) : (
                filteredTables.map(table => {
                  const status = tableStatus[table.id] || 'no_data'
                  return (
                    <tr key={table.id} className="border-b border-gray-800/60 hover:bg-gray-800/30 transition-colors">
                      <td className="px-4 py-3">
                        <Link to={`/tables/${table.id}`} className="flex items-center gap-2 group">
                          <div className={`w-2 h-2 rounded-full flex-shrink-0 ${STATUS_COLOR[status] || 'bg-gray-700'} ${STATUS_RING[status] ? `ring-2 ${STATUS_RING[status]}` : ''}`} />
                          <div>
                            <p className="text-sm text-gray-200 group-hover:text-blue-400 truncate max-w-[180px]">
                              {table.display_name || `${table.dataset_id}.${table.table_id}`}
                            </p>
                            <p className="text-xs text-gray-600 truncate max-w-[180px]">{table.dataset_id}</p>
                          </div>
                        </Link>
                      </td>
                      {MONITOR_TYPES.map(type => {
                        const runs = heatmap[table.id]?.[type] || []
                        return (
                          <td key={type} className="px-3 py-3">
                            <div className="flex items-center gap-1 justify-center">
                              {runs.length === 0 ? (
                                <div className="w-3 h-3 rounded-full bg-gray-800" title="No runs yet" />
                              ) : (
                                runs.slice(0, 8).map((run, i) => (
                                  <StatusDot
                                    key={i}
                                    status={run.status}
                                    tooltip={`${run.completed_at ? new Date(run.completed_at).toLocaleString() : '—'}: ${run.message || run.status}`}
                                  />
                                ))
                              )}
                            </div>
                          </td>
                        )
                      })}
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 text-xs text-gray-500">
        <span>Legend:</span>
        {Object.entries({ pass: 'Pass', warning: 'Warning', fail: 'Fail', error: 'Error' }).map(([s, label]) => (
          <span key={s} className="flex items-center gap-1.5">
            <span className={`w-2.5 h-2.5 rounded-full ${STATUS_COLOR[s]}`} /> {label}
          </span>
        ))}
        <span className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-gray-800" /> No data
        </span>
      </div>

      {/* Recent non-passing activity */}
      {recentActivity.length > 0 && (
        <div>
          <h2 className="text-sm font-medium text-gray-400 mb-3">Recent Issues</h2>
          <div className="space-y-2">
            {recentActivity.map(run => (
              <Link
                key={run.run_id}
                to={`/tables/${run.table_id}`}
                className="flex items-start gap-3 bg-gray-900 border border-gray-800 hover:border-gray-700 rounded-xl px-4 py-3 transition-colors"
              >
                <div className={`mt-0.5 w-2 h-2 rounded-full flex-shrink-0 ${STATUS_COLOR[run.status]}`} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-200 font-medium">{run.table_name}</span>
                    <span className="text-xs text-gray-600 bg-gray-800 px-1.5 py-0.5 rounded">
                      {MONITOR_LABELS[run.monitor_type] || run.monitor_type}
                    </span>
                  </div>
                  {run.message && <p className="text-xs text-gray-500 mt-0.5 truncate">{run.message}</p>}
                </div>
                <span className="text-xs text-gray-600 whitespace-nowrap flex-shrink-0">
                  {run.completed_at ? new Date(run.completed_at).toLocaleString() : ''}
                </span>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
