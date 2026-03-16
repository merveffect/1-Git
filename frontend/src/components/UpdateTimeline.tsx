import { useQuery } from '@tanstack/react-query'
import { getTableUpdateHistory } from '../api/client'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts'

interface UpdateEvent {
  id: number
  last_modified_time: string | null
  row_count: number | null
  detected_at: string | null
}

interface Props { tableId: number }

export default function UpdateTimeline({ tableId }: Props) {
  const { data: history = [], isLoading } = useQuery<UpdateEvent[]>({
    queryKey: ['update-history', tableId],
    queryFn: () => getTableUpdateHistory(tableId),
    refetchInterval: 60000,
  })

  if (isLoading) return <div className="text-gray-500 text-sm py-4">Loading update history...</div>

  if (history.length === 0) return (
    <div className="text-gray-600 text-sm py-4 text-center">
      No update history yet — the watcher checks every 5 minutes and records each time the table is refreshed.
    </div>
  )

  const chartData = history.map(e => ({
    time: e.detected_at ? new Date(e.detected_at).toLocaleDateString() : '',
    fullTime: e.detected_at ? new Date(e.detected_at).toLocaleString() : '',
    rows: e.row_count,
    modified: e.last_modified_time ? new Date(e.last_modified_time).toLocaleString() : '—',
  }))

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between text-xs text-gray-500">
        <span>{history.length} update{history.length !== 1 ? 's' : ''} recorded</span>
        <span>Last refresh: {history[history.length - 1]?.detected_at ? new Date(history[history.length - 1].detected_at!).toLocaleString() : '—'}</span>
      </div>

      {/* Row count over time */}
      {history.some(e => e.row_count != null) && (
        <ResponsiveContainer width="100%" height={160}>
          <AreaChart data={chartData} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
            <defs>
              <linearGradient id="rowGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
              </linearGradient>
            </defs>
            <XAxis dataKey="time" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
            <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} width={65} tickFormatter={v => v.toLocaleString()} />
            <Tooltip
              contentStyle={{ background: '#111827', border: '1px solid #374151', borderRadius: 8, fontSize: 12 }}
              labelFormatter={(_, payload) => payload?.[0]?.payload?.fullTime || ''}
              formatter={(v: number) => [v.toLocaleString(), 'Row Count']}
            />
            <Area type="monotone" dataKey="rows" stroke="#3b82f6" strokeWidth={2} fill="url(#rowGrad)" dot={{ r: 3, fill: '#3b82f6' }} />
          </AreaChart>
        </ResponsiveContainer>
      )}

      {/* Update event list */}
      <div className="space-y-1 max-h-40 overflow-y-auto">
        {[...history].reverse().map(e => (
          <div key={e.id} className="flex items-center gap-3 text-xs px-1">
            <div className="w-1.5 h-1.5 rounded-full bg-blue-400 flex-shrink-0" />
            <span className="text-gray-400">{e.detected_at ? new Date(e.detected_at).toLocaleString() : '—'}</span>
            {e.row_count != null && (
              <span className="text-gray-500">{e.row_count.toLocaleString()} rows</span>
            )}
            <span className="text-gray-600 truncate">BQ modified: {e.last_modified_time ? new Date(e.last_modified_time).toLocaleString() : '—'}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
