interface Props { status: string; size?: 'sm' | 'md' }
const colors: Record<string, string> = {
  pass: 'bg-green-500/20 text-green-400 border border-green-500/30',
  warning: 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30',
  fail: 'bg-red-500/20 text-red-400 border border-red-500/30',
  error: 'bg-gray-500/20 text-gray-400 border border-gray-500/30',
  running: 'bg-blue-500/20 text-blue-400 border border-blue-500/30',
  critical: 'bg-red-500/20 text-red-400 border border-red-500/30',
}
export default function StatusBadge({ status, size = 'sm' }: Props) {
  const cls = colors[status] || colors.error
  return (
    <span className={`inline-flex items-center rounded-full font-medium ${size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-3 py-1 text-sm'} ${cls}`}>
      {status.toUpperCase()}
    </span>
  )
}
