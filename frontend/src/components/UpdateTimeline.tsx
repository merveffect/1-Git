import { useQuery } from '@tanstack/react-query'
import { getTableUpdateHistory, getPartitionHistory } from '../api/client'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  ReferenceLine, Cell,
} from 'recharts'

interface UpdateEvent {
  id: number
  last_modified_time: string | null
  row_count: number | null
  detected_at: string | null
}

interface PartitionRow {
  partition_id: string
  total_rows: number | null
  last_modified_time: string | null
}

interface Props { tableId: number }

/** Parse YYYYMMDD or YYYYMM partition_id to a display label */
function formatPartitionId(pid: string): string {
  if (/^\d{8}$/.test(pid)) {
    return `${pid.slice(0, 4)}-${pid.slice(4, 6)}-${pid.slice(6, 8)}`
  }
  if (/^\d{6}$/.test(pid)) {
    return `${pid.slice(0, 4)}-${pid.slice(4, 6)}`
  }
  return pid
}

/** Is a partition from today (UTC)? */
function isToday(pid: string): boolean {
  const today = new Date()
  const todayStr = [
    today.getUTCFullYear(),
    String(today.getUTCMonth() + 1).padStart(2, '0'),
    String(today.getUTCDate()).padStart(2, '0'),
  ].join('')
  return pid === todayStr
}

const CustomTooltip = ({ active, payload }: any) => {
  if (!active || !payload?.length) return null
  const d = payload[0].payload
  return (
    <div className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-xs shadow-xl">
      <p className="font-medium text-white">{d.label}</p>
      {d.today && <p className="text-blue-400 text-[10px] mt-0.5">Today</p>}
      <p className="text-gray-300 mt-1">
        {d.rows != null ? d.rows.toLocaleString() + ' rows' : 'N/A'}
      </p>
      {d.lmt && (
        <p className="text-gray-500 mt-0.5">
          BQ modified: {new Date(d.lmt).toLocaleString()}
        </p>
      )}
    </div>
  )
}

export default function UpdateTimeline({ tableId }: Props) {
  const { data: partitions = [], isLoading: loadingParts } = useQuery<PartitionRow[]>({
    queryKey: ['partition-history', tableId],
    queryFn: () => getPartitionHistory(tableId),
    refetchInterval: 60000,
  })

  const { data: watcherEvents = [], isLoading: loadingEvents } = useQuery<UpdateEvent[]>({
    queryKey: ['update-history', tableId],
    queryFn: () => getTableUpdateHistory(tableId),
    refetchInterval: 60000,
  })

  const isLoading = loadingParts || loadingEvents

  if (isLoading) return <div className="text-gray-500 text-sm py-4">Loading update history...</div>

  // ── Build partition chart data ─────────────────────────────────────────────
  const hasPartitions = partitions.length > 0

  const chartData = hasPartitions
    ? partitions.map(p => ({
        pid: p.partition_id,
        label: formatPartitionId(p.partition_id),
        rows: p.total_rows,
        lmt: p.last_modified_time,
        today: isToday(p.partition_id),
      }))
    : watcherEvents.map(e => ({
        pid: e.detected_at ?? '',
        label: e.detected_at ? new Date(e.detected_at).toLocaleDateString() : '—',
        rows: e.row_count,
        lmt: e.last_modified_time,
        today: false,
      }))

  const totalRows = hasPartitions
    ? chartData.reduce((s, d) => s + (d.rows ?? 0), 0)
    : null

  const latestModified = hasPartitions
    ? partitions[partitions.length - 1]?.last_modified_time
    : watcherEvents[watcherEvents.length - 1]?.detected_at

  const hasData = chartData.length > 0

  if (!hasData) {
    return (
      <div className="text-gray-600 text-sm py-4 text-center">
        No update history yet — the watcher checks every 5 minutes and records each table refresh.
      </div>
    )
  }

  // Show at most 90 bars; if more, thin them by sampling
  const display = chartData.length > 90
    ? chartData.filter((_, i) => i % Math.ceil(chartData.length / 90) === 0 || i === chartData.length - 1)
    : chartData

  return (
    <div className="space-y-4">
      {/* Summary row */}
      <div className="flex flex-wrap items-center gap-4 text-xs text-gray-500">
        {hasPartitions && (
          <span>
            <span className="text-gray-300 font-medium">{partitions.length}</span> partitions
          </span>
        )}
        {totalRows != null && (
          <span>
            Total rows:{' '}
            <span className="text-gray-300 font-medium">{totalRows.toLocaleString()}</span>
          </span>
        )}
        {latestModified && (
          <span className="ml-auto">
            Last refresh:{' '}
            <span className="text-gray-300">{new Date(latestModified).toLocaleString()}</span>
          </span>
        )}
      </div>

      {/* Row count per partition bar chart */}
      <ResponsiveContainer width="100%" height={180}>
        <BarChart data={display} margin={{ top: 5, right: 8, left: 8, bottom: 5 }} barCategoryGap="15%">
          <XAxis
            dataKey="label"
            tick={{ fontSize: 10, fill: '#6b7280' }}
            tickLine={false}
            interval="preserveStartEnd"
          />
          <YAxis
            tick={{ fontSize: 10, fill: '#6b7280' }}
            tickLine={false}
            axisLine={false}
            width={70}
            tickFormatter={(v: number) => {
              if (v >= 1_000_000) return `${(v / 1_000_000).toFixed(1)}M`
              if (v >= 1_000) return `${(v / 1_000).toFixed(0)}K`
              return String(v)
            }}
          />
          <Tooltip content={<CustomTooltip />} />
          {/* Mark today's partition */}
          {display.some(d => d.today) && (
            <ReferenceLine
              x={display.find(d => d.today)?.label}
              stroke="#3b82f6"
              strokeDasharray="4 2"
              strokeOpacity={0.6}
            />
          )}
          <Bar dataKey="rows" radius={[2, 2, 0, 0]}>
            {display.map((d, i) => (
              <Cell
                key={i}
                fill={d.today ? '#3b82f6' : '#1d4ed8'}
                fillOpacity={d.today ? 1 : 0.65}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>

      {/* Legend hint */}
      <div className="flex items-center gap-4 text-[10px] text-gray-600">
        <span className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-sm bg-blue-800 opacity-65 inline-block" />
          Historical partition
        </span>
        <span className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-sm bg-blue-500 inline-block" />
          Today's partition
        </span>
        {!hasPartitions && (
          <span className="text-gray-600">— table is not partitioned; showing watcher events</span>
        )}
      </div>

      {/* Watcher event list (most recent first) */}
      {watcherEvents.length > 0 && (
        <div>
          <p className="text-[10px] text-gray-600 uppercase tracking-wider mb-1.5">
            Detected refresh events ({watcherEvents.length})
          </p>
          <div className="space-y-1 max-h-36 overflow-y-auto">
            {[...watcherEvents].reverse().map(e => (
              <div key={e.id} className="flex items-center gap-3 text-xs px-1">
                <div className="w-1.5 h-1.5 rounded-full bg-blue-400 flex-shrink-0" />
                <span className="text-gray-400">
                  {e.detected_at ? new Date(e.detected_at).toLocaleString() : '—'}
                </span>
                {e.row_count != null && (
                  <span className="text-gray-500">{e.row_count.toLocaleString()} rows</span>
                )}
                <span className="text-gray-600 truncate">
                  BQ modified: {e.last_modified_time ? new Date(e.last_modified_time).toLocaleString() : '—'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
