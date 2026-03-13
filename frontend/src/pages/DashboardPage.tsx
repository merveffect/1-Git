import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useTables, useDashboard } from '../hooks/useMonitors'
import { useAlerts } from '../hooks/useAlerts'
import { useQuery } from '@tanstack/react-query'
import { getTablesWithStatus } from '../api/client'
import AddTableModal from '../components/AddTableModal'
import StatusBadge from '../components/StatusBadge'
import AlertFeed from '../components/AlertFeed'
import { Plus, Table } from 'lucide-react'

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
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg text-sm font-medium">
          <Plus size={16} /> Add Table
        </button>
      </div>

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
          <h2 className="text-sm font-medium text-gray-400 mb-3">Monitored Tables</h2>
          {isLoading ? (
            <div className="text-gray-500 text-sm">Loading...</div>
          ) : tables.length === 0 ? (
            <div className="bg-gray-900 border border-dashed border-gray-700 rounded-xl p-8 text-center">
              <Table className="mx-auto text-gray-600 mb-3" size={32} />
              <p className="text-gray-400 text-sm mb-1">No tables monitored yet</p>
              <p className="text-gray-600 text-xs">Click "Add Table" to start monitoring your BigQuery tables</p>
            </div>
          ) : (
            <div className="space-y-2">
              {tables.map(table => (
                <Link key={table.id} to={`/tables/${table.id}`}
                  className="flex items-center justify-between bg-gray-900 border border-gray-800 hover:border-gray-700 rounded-xl px-4 py-3 transition-colors group">
                  <div>
                    <p className="text-sm font-medium text-white group-hover:text-blue-400">
                      {table.display_name || `${table.dataset_id}.${table.table_id}`}
                    </p>
                    <p className="text-xs text-gray-500">{table.project_id}</p>
                  </div>
                  <StatusBadge status={statusMap[table.id] || 'no_data'} />
                </Link>
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
