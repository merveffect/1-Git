import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { getDbtTestHistory } from '../api/client'
import { CheckCircle2, XCircle, AlertCircle, Clock } from 'lucide-react'

interface TestRun {
  run_at: string
  status: string
}

interface DbtTest {
  unique_id: string
  name: string
  test_type: string
  column_name: string | null
  section: 'dbt' | 'custom'
  latest_status: string
  failures: number | null
  history: TestRun[]
}

interface Props { modelName: string }

// ── Status helpers ────────────────────────────────────────────────────────────

const DOT_COLOR: Record<string, string> = {
  pass:    'bg-green-500',
  fail:    'bg-red-500',
  warn:    'bg-yellow-400',
  error:   'bg-gray-500',
  not_run: 'bg-gray-700',
}

const STATUS_ICON = (s: string) => {
  if (s === 'pass')  return <CheckCircle2 size={13} className="text-green-500" />
  if (s === 'fail')  return <XCircle size={13} className="text-red-500" />
  if (s === 'warn')  return <AlertCircle size={13} className="text-yellow-400" />
  if (s === 'error') return <AlertCircle size={13} className="text-gray-500" />
  return <Clock size={13} className="text-gray-600" />
}

const STATUS_TEXT: Record<string, string> = {
  pass: 'text-green-500',
  fail: 'text-red-500',
  warn: 'text-yellow-400',
  error: 'text-gray-500',
}

// ── Test type badge colors ────────────────────────────────────────────────────

const TYPE_COLOR: Record<string, string> = {
  not_null:         'bg-blue-950 text-blue-300 border-blue-800',
  unique:           'bg-purple-950 text-purple-300 border-purple-800',
  accepted_values:  'bg-orange-950 text-orange-300 border-orange-800',
  relationships:    'bg-teal-950 text-teal-300 border-teal-800',
  not_constant:     'bg-pink-950 text-pink-300 border-pink-800',
  expression_is_true: 'bg-indigo-950 text-indigo-300 border-indigo-800',
  custom:           'bg-gray-800 text-gray-400 border-gray-700',
}

function typeBadge(type: string) {
  const cls = TYPE_COLOR[type] ?? TYPE_COLOR.custom
  return (
    <span className={`text-[10px] font-mono px-1.5 py-0.5 rounded border ${cls}`}>
      {type}
    </span>
  )
}

// ── Single test card ──────────────────────────────────────────────────────────

function TestCard({ test }: { test: DbtTest }) {
  const borderCls =
    test.latest_status === 'fail'  ? 'border-red-500/40' :
    test.latest_status === 'warn'  ? 'border-yellow-500/40' :
    test.latest_status === 'pass'  ? 'border-green-500/20' :
    'border-gray-800'

  return (
    <div className={`bg-gray-950 border rounded-xl p-3.5 space-y-2 ${borderCls}`}>
      {/* Top row: type badge + column + status */}
      <div className="flex items-center gap-2 flex-wrap">
        {typeBadge(test.test_type)}
        {test.column_name && (
          <span className="text-xs text-gray-300 font-medium">{test.column_name}</span>
        )}
        <div className="ml-auto flex items-center gap-1.5">
          {STATUS_ICON(test.latest_status)}
          <span className={`text-[10px] font-semibold uppercase ${STATUS_TEXT[test.latest_status] ?? 'text-gray-500'}`}>
            {test.latest_status === 'not_run' ? 'not run' : test.latest_status}
          </span>
        </div>
      </div>

      {/* Test name */}
      <p className="text-[11px] text-gray-600 font-mono truncate" title={test.name}>
        {test.name}
      </p>

      {/* History dot timeline */}
      {test.history.length > 0 ? (
        <div className="flex items-center gap-1.5 flex-wrap pt-0.5">
          {test.history.map((run, i) => (
            <div key={i} className="relative group">
              <div className={`w-3 h-3 rounded-full ${DOT_COLOR[run.status] ?? 'bg-gray-700'} cursor-default`} />
              <div className="absolute bottom-5 left-1/2 -translate-x-1/2 z-10 hidden group-hover:block
                              bg-gray-800 border border-gray-700 text-[10px] text-gray-200
                              rounded-lg px-2 py-1 whitespace-nowrap shadow-xl pointer-events-none">
                <p>{new Date(run.run_at).toLocaleString()}</p>
                <p className={STATUS_TEXT[run.status] ?? 'text-gray-400'}>{run.status}</p>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <p className="text-[11px] text-gray-700 italic">No historical runs stored yet</p>
      )}

      {/* Failing rows count */}
      {test.failures != null && test.failures > 0 && (
        <p className="text-xs text-red-400">{test.failures.toLocaleString()} failing row(s)</p>
      )}
    </div>
  )
}

// ── Section (dbt Tests / Custom Tests) ───────────────────────────────────────

function TestSection({ title, tests }: { title: string; tests: DbtTest[] }) {
  if (tests.length === 0) return null

  const failCount = tests.filter(t => t.latest_status === 'fail').length
  const passCount = tests.filter(t => t.latest_status === 'pass').length

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider">{title}</h3>
        <span className="text-xs text-gray-600">{tests.length} test{tests.length !== 1 ? 's' : ''}</span>
        {failCount > 0 && (
          <span className="text-[10px] text-red-400 font-semibold ml-1">{failCount} failing</span>
        )}
        {passCount === tests.length && tests.length > 0 && (
          <span className="text-[10px] text-green-500 font-semibold ml-1">all passing</span>
        )}
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
        {tests.map(t => <TestCard key={t.unique_id} test={t} />)}
      </div>
    </div>
  )
}

// ── Main component ────────────────────────────────────────────────────────────

export default function DbtTestsDetail({ modelName }: Props) {
  const { data, isLoading } = useQuery({
    queryKey: ['dbt-test-history', modelName],
    queryFn: () => getDbtTestHistory(modelName),
    refetchInterval: 60000,
  })

  if (isLoading) {
    return <div className="text-gray-500 text-sm py-2">Loading dbt tests...</div>
  }

  if (!data?.configured) {
    return (
      <div className="text-center py-4 space-y-2">
        <p className="text-sm text-gray-500">dbt project path not configured.</p>
        <p className="text-xs text-gray-600">
          Go to{' '}
          <Link to="/settings" className="text-blue-400 hover:text-blue-300 underline">
            Settings
          </Link>{' '}
          and set your dbt project path, or add{' '}
          <code className="text-gray-400 text-[11px]">DBT_PROJECT_PATH=/path/to/dbt</code>{' '}
          to <code className="text-gray-400 text-[11px]">backend/.env</code>.
        </p>
      </div>
    )
  }

  const tests: DbtTest[] = data?.tests ?? []

  if (tests.length === 0) {
    return (
      <div className="text-sm text-gray-600 py-2 text-center">
        No dbt tests found for <code className="text-gray-500">{modelName}</code> in manifest.json.
      </div>
    )
  }

  const dbtTests    = tests.filter(t => t.section === 'dbt')
  const customTests = tests.filter(t => t.section === 'custom')

  return (
    <div className="space-y-6">
      <TestSection title="dbt Tests" tests={dbtTests} />
      <TestSection title="Custom Tests" tests={customTests} />
    </div>
  )
}
