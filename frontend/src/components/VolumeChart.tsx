import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'

interface DataPoint { date: string; value: number; status: string }
interface Props { data: DataPoint[] }

export default function VolumeChart({ data }: Props) {
  if (!data.length) return <div className="text-gray-500 text-sm py-4 text-center">No history yet</div>
  return (
    <ResponsiveContainer width="100%" height={160}>
      <LineChart data={data} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
        <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
        <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} width={60} tickFormatter={(v: number) => v.toLocaleString()} />
        <Tooltip
          contentStyle={{ background: '#111827', border: '1px solid #374151', borderRadius: 8, fontSize: 12 }}
          labelStyle={{ color: '#9ca3af' }}
          formatter={(v: number) => [v.toLocaleString(), 'Row Count']}
        />
        <Line type="monotone" dataKey="value" stroke="#3b82f6" strokeWidth={2} dot={(p: { key: string; cx: number; cy: number; payload: DataPoint }) => {
          const isAnomaly = p.payload.status === 'fail'
          return <circle key={p.key} cx={p.cx} cy={p.cy} r={isAnomaly ? 5 : 3} fill={isAnomaly ? '#ef4444' : '#3b82f6'} />
        }} />
      </LineChart>
    </ResponsiveContainer>
  )
}
