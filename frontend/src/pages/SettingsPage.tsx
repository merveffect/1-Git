import { useState, useEffect } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import axios from 'axios'
import { CheckCircle, AlertCircle, Download, FolderOpen, X } from 'lucide-react'

const api = axios.create({ baseURL: '/api' })

interface DbtStatus {
  configured: boolean
  project_path: string | null
  project_name: string | null
  model_count: number
}

export default function SettingsPage() {
  const qc = useQueryClient()
  const [dbtPath, setDbtPath] = useState('')
  const [saving, setSaving] = useState(false)
  const [clearing, setClearing] = useState(false)
  const [importing, setImporting] = useState(false)
  const [msg, setMsg] = useState<{ type: 'ok' | 'err'; text: string } | null>(null)

  const { data: status, refetch } = useQuery<DbtStatus>({
    queryKey: ['dbt-status'],
    queryFn: () => api.get('/dbt/status').then(r => r.data),
  })

  // Pre-populate input with current path so user can edit it directly
  useEffect(() => {
    if (status?.project_path && !dbtPath) {
      setDbtPath(status.project_path)
    }
  }, [status?.project_path])

  const savePath = async () => {
    if (!dbtPath.trim()) return
    setSaving(true)
    setMsg(null)
    try {
      await api.post('/dbt/settings', { dbt_project_path: dbtPath.trim() })
      setMsg({ type: 'ok', text: 'Path saved. Restart the backend for it to take effect.' })
      refetch()
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string } } }
      setMsg({ type: 'err', text: err.response?.data?.detail || 'Failed to save' })
    } finally {
      setSaving(false)
    }
  }

  const clearPath = async () => {
    setClearing(true)
    setMsg(null)
    try {
      await api.post('/dbt/settings/clear')
      setDbtPath('')
      setMsg({ type: 'ok', text: 'dbt path cleared. Restart the backend to apply.' })
      refetch()
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string } } }
      setMsg({ type: 'err', text: err.response?.data?.detail || 'Failed to clear' })
    } finally {
      setClearing(false)
    }
  }

  const importModels = async () => {
    setImporting(true)
    setMsg(null)
    try {
      const res = await api.post('/dbt/import')
      setMsg({ type: 'ok', text: `Imported ${res.data.imported} models (${res.data.skipped} already existed)` })
      qc.invalidateQueries({ queryKey: ['tables'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string } } }
      setMsg({ type: 'err', text: err.response?.data?.detail || 'Import failed' })
    } finally {
      setImporting(false)
    }
  }

  const inputCls = "w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Settings</h1>
        <p className="text-gray-500 text-sm mt-0.5">Configure your dbt project and monitoring defaults</p>
      </div>

      {/* dbt Integration */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5 space-y-4">
        <div className="flex items-center gap-2">
          <FolderOpen className="text-orange-400" size={18} />
          <h2 className="text-base font-semibold text-white">dbt Core Integration</h2>
          {status?.configured ? (
            <span className="ml-auto flex items-center gap-1 text-xs text-green-400">
              <CheckCircle size={13} /> Connected
            </span>
          ) : (
            <span className="ml-auto flex items-center gap-1 text-xs text-gray-500">
              <AlertCircle size={13} /> Not configured
            </span>
          )}
        </div>

        {status?.configured && (
          <div className="bg-gray-800 rounded-lg px-4 py-3 space-y-1 text-sm">
            <p className="text-gray-400">Project: <span className="text-white font-medium">{status.project_name || '—'}</span></p>
            <p className="text-gray-400">Path: <span className="text-gray-300 font-mono text-xs">{status.project_path}</span></p>
            <p className="text-gray-400">Models in manifest: <span className="text-white font-medium">{status.model_count}</span></p>
          </div>
        )}

        <div>
          <label className="block text-xs text-gray-400 mb-1 font-medium">
            dbt Project Path <span className="text-gray-600">(folder containing dbt_project.yml)</span>
          </label>
          <input
            className={inputCls}
            value={dbtPath}
            onChange={e => setDbtPath(e.target.value)}
            placeholder="/Users/you/your-dbt-project"
          />
          <p className="text-xs text-gray-600 mt-1">
            You can also set <code className="text-gray-500">DBT_PROJECT_PATH</code> in <code className="text-gray-500">backend/.env</code>
          </p>
        </div>

        <div className="flex gap-3 flex-wrap">
          <button
            onClick={savePath}
            disabled={saving || !dbtPath.trim()}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white text-sm rounded-lg font-medium disabled:opacity-40"
          >
            {saving ? 'Saving...' : 'Save Path'}
          </button>

          {status?.configured && (
            <button
              onClick={importModels}
              disabled={importing}
              className="flex items-center gap-2 px-4 py-2 bg-orange-600 hover:bg-orange-500 text-white text-sm rounded-lg font-medium disabled:opacity-40"
            >
              <Download size={14} />
              {importing ? 'Importing...' : `Import ${status.model_count} Models`}
            </button>
          )}

          {status?.configured && (
            <button
              onClick={clearPath}
              disabled={clearing}
              className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 text-sm rounded-lg font-medium disabled:opacity-40"
            >
              <X size={14} />
              {clearing ? 'Clearing...' : 'Clear Path'}
            </button>
          )}
        </div>

        {msg && (
          <p className={`text-sm ${msg.type === 'ok' ? 'text-green-400' : 'text-red-400'}`}>
            {msg.text}
          </p>
        )}
      </div>

      {/* How-to note */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
        <h2 className="text-sm font-semibold text-white mb-3">Setup Instructions</h2>
        <ol className="space-y-2 text-sm text-gray-400 list-decimal list-inside">
          <li>Install gcloud CLI: <a href="https://cloud.google.com/sdk/docs/install" target="_blank" className="text-blue-400 underline">cloud.google.com/sdk/docs/install</a></li>
          <li>Authenticate: <code className="bg-gray-800 px-1.5 py-0.5 rounded text-gray-300 text-xs">gcloud auth application-default login</code></li>
          <li>Set your dbt project path above and click Save</li>
          <li>Click <strong className="text-white">Import Models</strong> to pull all dbt models into the monitor</li>
          <li>Or use <strong className="text-white">Add Table</strong> on the dashboard to add individual tables</li>
        </ol>
      </div>
    </div>
  )
}
