import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { addDbtPath, removeDbtPath, importDbtModels } from '../api/client'
import {
  CheckCircle, AlertCircle, Download, FolderOpen, Plus, Trash2, Package,
} from 'lucide-react'
import axios from 'axios'

const api = axios.create({ baseURL: '/api' })

interface ProjectInfo {
  path: string
  target_exists: boolean
  project_name: string | null
  model_count: number
  configured: boolean
}

interface DbtStatus {
  configured: boolean
  project_path: string | null
  project_name: string | null
  model_count: number
  projects: ProjectInfo[]
}

export default function SettingsPage() {
  const qc = useQueryClient()
  const [newPath, setNewPath] = useState('')
  const [adding, setAdding] = useState(false)
  const [importingPath, setImportingPath] = useState<string | null>(null)
  const [removingPath, setRemovingPath] = useState<string | null>(null)
  const [msg, setMsg] = useState<{ type: 'ok' | 'err'; text: string } | null>(null)

  const { data: status, refetch } = useQuery<DbtStatus>({
    queryKey: ['dbt-status'],
    queryFn: () => api.get('/dbt/status').then(r => r.data),
  })

  const projects: ProjectInfo[] = status?.projects ?? []

  const flash = (type: 'ok' | 'err', text: string) => {
    setMsg({ type, text })
    setTimeout(() => setMsg(null), 5000)
  }

  const handleAdd = async () => {
    const path = newPath.trim()
    if (!path) return
    setAdding(true)
    try {
      await addDbtPath(path)
      setNewPath('')
      flash('ok', `Project added: ${path}`)
      refetch()
    } catch (e: any) {
      flash('err', e?.response?.data?.detail || 'Failed to add project')
    } finally {
      setAdding(false)
    }
  }

  const handleImport = async (projectPath?: string) => {
    setImportingPath(projectPath ?? '__all__')
    try {
      const res = await importDbtModels(projectPath)
      flash('ok', `Imported ${res.imported} model(s) — ${res.skipped} already existed`)
      qc.invalidateQueries({ queryKey: ['tables'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
    } catch (e: any) {
      flash('err', e?.response?.data?.detail || 'Import failed')
    } finally {
      setImportingPath(null)
    }
  }

  const handleRemove = async (path: string) => {
    setRemovingPath(path)
    try {
      await removeDbtPath(path)
      flash('ok', `Removed: ${path}`)
      refetch()
    } catch (e: any) {
      flash('err', e?.response?.data?.detail || 'Failed to remove')
    } finally {
      setRemovingPath(null)
    }
  }

  const inputCls = "w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Settings</h1>
        <p className="text-gray-500 text-sm mt-0.5">Configure dbt projects and monitoring</p>
      </div>

      {/* dbt Projects */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5 space-y-5">
        <div className="flex items-center gap-2">
          <FolderOpen className="text-orange-400" size={18} />
          <h2 className="text-base font-semibold text-white">dbt Core Projects</h2>
          {status?.configured ? (
            <span className="ml-auto flex items-center gap-1 text-xs text-green-400">
              <CheckCircle size={13} />
              {projects.filter(p => p.configured).length} connected
            </span>
          ) : (
            <span className="ml-auto flex items-center gap-1 text-xs text-gray-500">
              <AlertCircle size={13} /> Not configured
            </span>
          )}
        </div>

        {/* Configured project list */}
        {projects.length > 0 && (
          <div className="space-y-2">
            {projects.map(proj => (
              <div
                key={proj.path}
                className={`border rounded-xl p-4 space-y-2 ${
                  proj.configured ? 'border-gray-700 bg-gray-800/50' : 'border-red-900/40 bg-red-950/10'
                }`}
              >
                {/* Header */}
                <div className="flex items-start gap-3">
                  <Package
                    size={15}
                    className={proj.configured ? 'text-orange-400 mt-0.5 flex-shrink-0' : 'text-gray-600 mt-0.5 flex-shrink-0'}
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-medium text-white truncate">
                        {proj.project_name || proj.path.split('/').pop() || proj.path}
                      </span>
                      {proj.configured ? (
                        <span className="text-[10px] text-green-400 flex items-center gap-0.5">
                          <CheckCircle size={10} /> connected
                        </span>
                      ) : (
                        <span className="text-[10px] text-red-400 flex items-center gap-0.5">
                          <AlertCircle size={10} /> target/ not found
                        </span>
                      )}
                    </div>
                    <p className="text-[11px] text-gray-500 font-mono truncate mt-0.5">{proj.path}</p>
                    {proj.configured && (
                      <p className="text-xs text-gray-500 mt-0.5">
                        {proj.model_count} model{proj.model_count !== 1 ? 's' : ''} in manifest
                      </p>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex gap-2 flex-wrap pl-6">
                  {proj.configured && (
                    <button
                      onClick={() => handleImport(proj.path)}
                      disabled={importingPath === proj.path}
                      className="flex items-center gap-1.5 px-3 py-1.5 bg-orange-700 hover:bg-orange-600 text-white text-xs rounded-lg font-medium disabled:opacity-40"
                    >
                      <Download size={12} />
                      {importingPath === proj.path ? 'Importing...' : `Import ${proj.model_count} Models`}
                    </button>
                  )}
                  <button
                    onClick={() => handleRemove(proj.path)}
                    disabled={removingPath === proj.path}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-gray-300 text-xs rounded-lg font-medium disabled:opacity-40"
                  >
                    <Trash2 size={12} />
                    {removingPath === proj.path ? 'Removing...' : 'Remove'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Import all button (shown when >1 project) */}
        {projects.filter(p => p.configured).length > 1 && (
          <button
            onClick={() => handleImport()}
            disabled={importingPath === '__all__'}
            className="flex items-center gap-2 px-4 py-2 bg-orange-600 hover:bg-orange-500 text-white text-sm rounded-lg font-medium disabled:opacity-40 w-full justify-center"
          >
            <Download size={14} />
            {importingPath === '__all__' ? 'Importing...' : 'Import All Projects'}
          </button>
        )}

        {/* Add new project */}
        <div className="border-t border-gray-800 pt-4 space-y-2">
          <label className="block text-xs text-gray-400 font-medium">
            Add dbt Project{' '}
            <span className="text-gray-600 font-normal">(path to folder containing dbt_project.yml)</span>
          </label>
          <div className="flex gap-2">
            <input
              className={inputCls}
              value={newPath}
              onChange={e => setNewPath(e.target.value)}
              placeholder="/Users/you/your-dbt-project"
              onKeyDown={e => e.key === 'Enter' && handleAdd()}
            />
            <button
              onClick={handleAdd}
              disabled={adding || !newPath.trim()}
              className="flex items-center gap-1.5 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white text-sm rounded-lg font-medium disabled:opacity-40 whitespace-nowrap"
            >
              <Plus size={14} />
              {adding ? 'Adding...' : 'Add'}
            </button>
          </div>
          <p className="text-xs text-gray-600">
            You can also set{' '}
            <code className="text-gray-500">DBT_PROJECT_PATHS=/path/1,/path/2</code>{' '}
            in <code className="text-gray-500">backend/.env</code>
          </p>
        </div>

        {msg && (
          <p className={`text-sm ${msg.type === 'ok' ? 'text-green-400' : 'text-red-400'}`}>
            {msg.text}
          </p>
        )}
      </div>

      {/* Setup instructions */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
        <h2 className="text-sm font-semibold text-white mb-3">Setup Instructions</h2>
        <ol className="space-y-2 text-sm text-gray-400 list-decimal list-inside">
          <li>
            Install gcloud CLI:{' '}
            <a
              href="https://cloud.google.com/sdk/docs/install"
              target="_blank"
              rel="noreferrer"
              className="text-blue-400 underline"
            >
              cloud.google.com/sdk/docs/install
            </a>
          </li>
          <li>
            Authenticate:{' '}
            <code className="bg-gray-800 px-1.5 py-0.5 rounded text-gray-300 text-xs">
              gcloud auth application-default login
            </code>
          </li>
          <li>Add each dbt project path above and click Add</li>
          <li>Click <strong className="text-white">Import Models</strong> per project to pull models into the monitor</li>
          <li>Or use <strong className="text-white">Add Table</strong> on the dashboard for individual BigQuery tables</li>
        </ol>
      </div>
    </div>
  )
}
