import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { getDbtRunHistory, getDbtSnapshotResults } from '../api/client'
import { CheckCircle, XCircle, AlertTriangle, Clock, ChevronDown, ChevronRight, SkipForward } from 'lucide-react'

interface RunSnapshot {
  id: number
  run_at: string | null
  detected_at: string | null
  elapsed_time: number | null
  models: { pass: number; fail: number; error: number; skip: number }
  tests: { pass: number; fail: number; error: number; warn: number }
}

interface NodeResult {
  unique_id: string
  status: string
  execution_time?: number
  failures?: number
  message?: string
}

const STATUS_ICON: Record<string, JSX.Element> = {
  success: <CheckCircle size={13} className="text-green-400" />,
  pass:    <CheckCircle size={13} className="text-green-400" />,
  fail:    <XCircle size={13} className="text-red-400" />,
  error:   <XCircle size={13} className="text-red-400" />,
  warn:    <AlertTriangle size={13} className="text-yellow-400" />,
  skip:    <SkipForward size={13} className="text-gray-500" />,
}

const STATUS_TEXT: Record<string, string> = {
  success: 'text-green-400',
  pass:    'text-green-400',
  fail:    'text-red-400',
  error:   'text-red-400',
  warn:    'text-yellow-400',
  skip:    'text-gray-500',
}

function RunBar({ label, value, total, color }: { label: string; value: number; total: number; color: string }) {
  const pct = total > 0 ? (value / total) * 100 : 0
  if (value === 0) return null
  return (
    <div className="flex items-center gap-2 text-xs">
      <span className={`w-16 text-right ${color}`}>{value} {label}</span>
      <div className="flex-1 bg-gray-800 rounded-full h-1.5 max-w-24">
        <div className={`h-1.5 rounded-full ${color.replace('text-', 'bg-')}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  )
}

function SnapshotRow({ run }: { run: RunSnapshot }) {
  const [expanded, setExpanded] = useState(false)
  const totalModels = run.models.pass + run.models.fail + run.models.error + run.models.skip
  const totalTests  = run.tests.pass  + run.tests.fail  + run.tests.error  + run.tests.warn
  const hasFails = run.models.fail > 0 || run.models.error > 0 || run.tests.fail > 0 || run.tests.error > 0
  const hasWarns = run.tests.warn > 0

  const overallStatus = hasFails ? 'fail' : hasWarns ? 'warn' : 'pass'
  const statusDot = {
    fail: 'bg-red-500',
    warn: 'bg-yellow-400',
    pass: 'bg-green-500',
  }[overallStatus]

  const { data: drillDown } = useQuery({
    queryKey: ['snapshot-results', run.id],
    queryFn: () => getDbtSnapshotResults(run.id),
    enabled: expanded,
  })

  const failedNodes: NodeResult[] = drillDown
    ? drillDown.results.filter((r: NodeResult) => ['fail', 'error'].includes(r.status))
    : []

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
      <button
        onClick={() => setExpanded(e => !e)}
        className="w-full flex items-center gap-4 px-4 py-3 hover:bg-gray-800/50 transition-colors text-left"
      >
        <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${statusDot}`} />

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-3">
            <span className="text-sm font-medium text-white">
              {run.run_at ? new Date(run.run_at).toLocaleString() : '—'}
            </span>
            {run.elapsed_time && (
              <span className="flex items-center gap-1 text-xs text-gray-500">
                <Clock size={11} /> {run.elapsed_time.toFixed(1)}s
              </span>
            )}
          </div>
          <div className="flex items-center gap-4 mt-1">
            {totalModels > 0 && (
              <span className="text-xs text-gray-500">
                Models: <span className="text-green-400">{run.models.pass}✓</span>
                {run.models.fail > 0 && <span className="text-red-400 ml-1">{run.models.fail}✗</span>}
                {run.models.skip > 0 && <span className="text-gray-500 ml-1">{run.models.skip} skip</span>}
              </span>
            )}
            {totalTests > 0 && (
              <span className="text-xs text-gray-500">
                Tests: <span className="text-green-400">{run.tests.pass}✓</span>
                {run.tests.fail > 0 && <span className="text-red-400 ml-1">{run.tests.fail}✗</span>}
                {run.tests.warn > 0 && <span className="text-yellow-400 ml-1">{run.tests.warn}⚠</span>}
              </span>
            )}
          </div>
        </div>

        {/* Mini bar chart */}
        <div className="hidden sm:flex flex-col gap-1 w-32">
          {totalModels > 0 && (
            <div className="flex h-2 rounded-full overflow-hidden gap-px">
              {run.models.pass  > 0 && <div className="bg-green-500" style={{ flex: run.models.pass }} />}
              {run.models.fail  > 0 && <div className="bg-red-500"   style={{ flex: run.models.fail }} />}
              {run.models.error > 0 && <div className="bg-red-700"   style={{ flex: run.models.error }} />}
              {run.models.skip  > 0 && <div className="bg-gray-600"  style={{ flex: run.models.skip }} />}
            </div>
          )}
          {totalTests > 0 && (
            <div className="flex h-2 rounded-full overflow-hidden gap-px">
              {run.tests.pass  > 0 && <div className="bg-green-500"  style={{ flex: run.tests.pass }} />}
              {run.tests.fail  > 0 && <div className="bg-red-500"    style={{ flex: run.tests.fail }} />}
              {run.tests.warn  > 0 && <div className="bg-yellow-400" style={{ flex: run.tests.warn }} />}
              {run.tests.error > 0 && <div className="bg-red-700"    style={{ flex: run.tests.error }} />}
            </div>
          )}
        </div>

        {expanded ? <ChevronDown size={16} className="text-gray-500 flex-shrink-0" /> : <ChevronRight size={16} className="text-gray-500 flex-shrink-0" />}
      </button>

      {/* Drill-down: failing nodes */}
      {expanded && (
        <div className="border-t border-gray-800 px-4 py-3 space-y-2">
          {!drillDown && <p className="text-xs text-gray-500">Loading...</p>}
          {drillDown && failedNodes.length === 0 && (
            <p className="text-xs text-gray-500 flex items-center gap-1.5">
              <CheckCircle size={13} className="text-green-400" /> All models and tests passed this run
            </p>
          )}
          {failedNodes.map(node => {
            const name = node.unique_id.split('.').slice(-1)[0]
            const rtype = node.unique_id.split('.')[0]
            return (
              <div key={node.unique_id} className="flex items-start gap-2">
                {STATUS_ICON[node.status] || STATUS_ICON.error}
                <div className="min-w-0">
                  <span className="text-xs font-mono text-gray-300">{name}</span>
                  <span className="text-xs text-gray-600 ml-2">{rtype}</span>
                  {node.message && (
                    <p className="text-xs text-gray-500 mt-0.5 truncate max-w-lg">{node.message}</p>
                  )}
                </div>
                {node.execution_time && (
                  <span className="ml-auto text-xs text-gray-600 flex-shrink-0">{node.execution_time.toFixed(2)}s</span>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

export default function DbtHistoryPage() {
  const { data: runs = [], isLoading } = useQuery<RunSnapshot[]>({
    queryKey: ['dbt-run-history'],
    queryFn: () => getDbtRunHistory(100),
    refetchInterval: 30000,
  })

  const totalRuns   = runs.length
  const failedRuns  = runs.filter(r => r.models.fail > 0 || r.models.error > 0 || r.tests.fail > 0).length
  const successRuns = totalRuns - failedRuns

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">dbt Run History</h1>
        <p className="text-gray-500 text-sm mt-0.5">
          Every dbt run detected since monitoring started — file watcher checks every 2 minutes
        </p>
      </div>

      {/* Summary stats */}
      {totalRuns > 0 && (
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
            <p className="text-xs text-gray-500 mb-1">Total Runs</p>
            <p className="text-2xl font-bold text-white">{totalRuns}</p>
          </div>
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
            <p className="text-xs text-gray-500 mb-1">Successful</p>
            <p className="text-2xl font-bold text-green-400">{successRuns}</p>
          </div>
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
            <p className="text-xs text-gray-500 mb-1">With Failures</p>
            <p className="text-2xl font-bold text-red-400">{failedRuns}</p>
          </div>
        </div>
      )}

      {/* Run list */}
      {isLoading ? (
        <div className="text-gray-500 text-sm">Loading...</div>
      ) : runs.length === 0 ? (
        <div className="bg-gray-900 border border-dashed border-gray-700 rounded-xl p-10 text-center">
          <Clock className="mx-auto text-gray-600 mb-3" size={32} />
          <p className="text-gray-400 text-sm font-medium">No dbt runs recorded yet</p>
          <p className="text-gray-600 text-xs mt-1 max-w-sm mx-auto">
            The watcher checks every 2 minutes. Run <code className="text-gray-500">dbt run</code> or{' '}
            <code className="text-gray-500">dbt test</code> in your project — it'll appear here automatically.
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {runs.map(run => <SnapshotRow key={run.id} run={run} />)}
        </div>
      )}
    </div>
  )
}
