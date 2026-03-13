import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useTables, useDashboard } from '../hooks/useMonitors'
import { useAlerts } from '../hooks/useAlerts'
import { useQuery } from '@tanstack/react-query'
import { getTablesWithStatus } from '../api/client'
import AddTableModal from '../components/AddTableModal'
import StatusBadge from '../components/StatusBadge'
import AlertFeed from '../components/AlertFeed'
import { Plus, Table, ChevronDown, ChevronRight, FolderOpen, Folder } from 'lucide-react'
import type { MonitoredTable } from '../types'

interface TableWithStatus extends MonitoredTable {
  status: string
}

const STATUS_PRIORITY: Record<string, number> = { fail: 3, error: 2, warning: 1, pass: 0, no_data: -1 }

function worstStatus(statuses: string[]): string {
  return statuses.reduce((worst, s) =>
    (STATUS_PRIORITY[s] ?? -1) > (STATUS_PRIORITY[worst] ?? -1) ? s : worst
  , 'no_data')
}

interface FolderGroup {
  key: string           // project_id::dataset_id
  project_id: string
  dataset_id: string
  tables: TableWithStatus[]
  status: string
}

function buildFolders(tables: MonitoredTable[], statusMap: Record<number, string>): FolderGroup[] {
  const groups: Record<string, FolderGroup> = {}
  for (const t of tables) {
    const key = `${t.project_id}::${t.dataset_id}`
    if (!groups[key]) {
      groups[key] = { key, project_id: t.project_id, dataset_id: t.dataset_id, tables: [], status: 'no_data' }
    }
    groups[key].tables.push({ ...t, status: statusMap[t.id] || 'no_data' })
  }
  // compute worst status per folder
  for (const g of Object.values(groups)) {
    g.status = worstStatus(g.tables.map(t => t.status))
  }
  // sort: failing first, then by dataset name
  return Object.values(groups).sort((a, b) =>
    (STATUS_PRIORITY[b.status] ?? -1) - (STATUS_PRIORITY[a.status] ?? -1) ||
    a.dataset_id.localeCompare(b.dataset_id)
  )
}

interface FolderRowProps {
  group: FolderGroup
  defaultOpen?: boolean
}

function FolderRow({ group, defaultOpen = false }: FolderRowProps) {
  const [open, setOpen] = useState(defaultOpen || group.status === 'fail' || group.status === 'error')

  const hasFail = group.tables.some(t => ['fail', 'error'].includes(t.status))

  return (
    <div className={`bg-gray-900 border rounded-xl overflow-hidden transition-colors ${
      hasFail ? 'border-red-500/30' : 'border-gray-800'
    }`}>
      {/* Folder header */}
      <button
        onClick={() => setOpen(o => !o)}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-800/50 transition-colors"
      >
        {open
          ? <FolderOpen size={16} className="text-blue-400 flex-shrink-0" />
          : <Folder size={16} className="text-gray-500 flex-shrink-0" />
        }
        <div className="flex-1 text-left min-w-0">
          <p className="text-sm font-semibold text-white truncate">{group.dataset_id}</p>
          <p className="text-xs text-gray-500 truncate">{group.project_id}</p>
        </div>
        <span className="text-xs text-gray-600 mr-2">{group.tables.length} table{group.tables.length !== 1 ? 's' : ''}</span>
        <StatusBadge status={group.status} />
        {open
          ? <ChevronDown size={14} className="text-gray-500 flex-shrink-0 ml-2" />
          : <ChevronRight size={14} className="text-gray-500 flex-shrink-0 ml-2" />
        }
      </button>

      {/* Table rows */}
      {open && (
        <div className="border-t border-gray-800 divide-y divide-gray-800/60">
          {group.tables.map(table => (
            <Link
              key={table.id}
              to={`/tables/${table.id}`}
              className="flex items-center gap-3 pl-10 pr-4 py-2.5 hover:bg-gray-800/40 transition-colors group"
            >
              <div className="flex-1 min-w-0">
                <p className="text-sm text-gray-300 group-hover:text-blue-400 truncate">
                  {table.table_id}
                </p>
                {table.display_name && table.display_name !== `${table.dataset_id}.${table.table_id}` && (
                  <p className="text-xs text-gray-600 truncate">{table.display_name}</p>
                )}
              </div>
              <StatusBadge status={table.status} />
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

export default function DashboardPage() {
  const [showAdd, setShowAdd] = useState(false)
  const { data: tables = [], isLoading } = useTables()
  const { data: stats } = useDashboard()
  const { data: alerts = [] } = useAlerts({ acknowledged: false, limit: 10 })
  const { data: tablesWithStatus = [] } = useQuery({
    queryKey: ['tables-with-status'],
    queryFn: getTablesWithStatus,
    refetchInterval: 30000,
  })

  const statusMap: Record<number, string> = Object.fromEntries(
    tablesWithStatus.map((t: { id: number; status: string }) => [t.id, t.status])
  )

  const folders = buildFolders(tables, statusMap)

  const statCards = [
    { label: 'Monitored Tables', value: stats?.total_tables ?? 0, color: 'text-white' },
    { label: 'Passing', value: stats?.passing ?? 0, color: 'text-green-400' },
    { label: 'Warnings', value: stats?.warning ?? 0, color: 'text-yellow-400' },
    { label: 'Failing', value: stats?.failing ?? 0, color: 'text-red-400' },
  ]

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Dashboard</h1>
          <p className="text-gray-500 text-sm mt-0.5">Data pipeline health overview</p>
        </div>
        <button
          onClick={() => setShowAdd(true)}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg text-sm font-medium"
        >
          <Plus size={16} /> Add Table
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {statCards.map(({ label, value, color }) => (
          <div key={label} className="bg-gray-900 border border-gray-800 rounded-xl p-4">
            <p className="text-xs text-gray-500 mb-1">{label}</p>
            <p className={`text-3xl font-bold ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-medium text-gray-400">
              Pipelines
              {folders.length > 0 && (
                <span className="ml-2 text-gray-600 font-normal">
                  {folders.length} dataset{folders.length !== 1 ? 's' : ''} · {tables.length} tables
                </span>
              )}
            </h2>
          </div>

          {isLoading ? (
            <div className="text-gray-500 text-sm">Loading...</div>
          ) : tables.length === 0 ? (
            <div className="bg-gray-900 border border-dashed border-gray-700 rounded-xl p-8 text-center">
              <Table className="mx-auto text-gray-600 mb-3" size={32} />
              <p className="text-gray-400 text-sm mb-1">No tables monitored yet</p>
              <p className="text-gray-600 text-xs">
                Click "Add Table" to add individual tables, or go to{' '}
                <Link to="/settings" className="text-blue-400 hover:underline">Settings</Link>{' '}
                to import all dbt models at once.
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {folders.map(group => (
                <FolderRow
                  key={group.key}
                  group={group}
                  defaultOpen={folders.length === 1}
                />
              ))}
            </div>
          )}
        </div>

        <div>
          <h2 className="text-sm font-medium text-gray-400 mb-3">Recent Alerts</h2>
          <AlertFeed alerts={alerts.slice(0, 5)} />
        </div>
      </div>

      {showAdd && <AddTableModal onClose={() => setShowAdd(false)} />}
    </div>
  )
}
