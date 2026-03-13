import { ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { LayoutDashboard, Bell, Database, Settings, History, GitCommitHorizontal } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { getDashboardStats } from '../api/client'

export default function Layout({ children }: { children: ReactNode }) {
  const location = useLocation()
  const { data: stats } = useQuery({ queryKey: ['dashboard'], queryFn: getDashboardStats, refetchInterval: 30000 })

  const navItems = [
    { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
    { to: '/history', icon: History, label: 'History' },
    { to: '/dbt-history', icon: GitCommitHorizontal, label: 'dbt Runs' },
    { to: '/alerts', icon: Bell, label: 'Alerts', badge: stats?.unacknowledged_alerts },
    { to: '/settings', icon: Settings, label: 'Settings' },
  ]

  return (
    <div className="flex h-screen bg-gray-950 text-gray-100">
      <aside className="w-56 bg-gray-900 border-r border-gray-800 flex flex-col">
        <div className="p-4 border-b border-gray-800">
          <div className="flex items-center gap-2">
            <Database className="text-blue-400" size={20} />
            <span className="font-semibold text-white">DataMonitor</span>
          </div>
          <p className="text-xs text-gray-500 mt-1">Pipeline Observability</p>
        </div>
        <nav className="flex-1 p-3 space-y-1">
          {navItems.map(({ to, icon: Icon, label, badge }) => (
            <Link
              key={to}
              to={to}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                location.pathname === to
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-400 hover:text-white hover:bg-gray-800'
              }`}
            >
              <Icon size={16} />
              <span className="flex-1">{label}</span>
              {badge != null && badge > 0 && (
                <span className="bg-red-500 text-white text-xs rounded-full px-1.5 py-0.5 min-w-[20px] text-center">
                  {badge}
                </span>
              )}
            </Link>
          ))}
        </nav>
      </aside>
      <main className="flex-1 overflow-auto p-6">{children}</main>
    </div>
  )
}
