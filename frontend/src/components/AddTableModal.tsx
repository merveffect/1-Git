import { useState } from 'react'
import { addTable } from '../api/client'
import { useQueryClient } from '@tanstack/react-query'
import { X } from 'lucide-react'

interface Props { onClose: () => void }

export default function AddTableModal({ onClose }: Props) {
  const [projectId, setProjectId] = useState('dat-analytics-eng-ec869189')
  const [datasetId, setDatasetId] = useState('')
  const [tableId, setTableId] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const qc = useQueryClient()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      await addTable({ project_id: projectId, dataset_id: datasetId, table_id: tableId })
      qc.invalidateQueries({ queryKey: ['tables'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      onClose()
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to add table')
    } finally {
      setLoading(false)
    }
  }

  const inputCls = "w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
  const labelCls = "block text-xs text-gray-400 mb-1 font-medium"

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-gray-900 border border-gray-700 rounded-2xl w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-5">
          <h2 className="text-lg font-semibold text-white">Add BigQuery Table</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className={labelCls}>GCP Project ID</label>
            <input className={inputCls} value={projectId} onChange={e => setProjectId(e.target.value)} placeholder="my-project-123" required />
          </div>
          <div>
            <label className={labelCls}>Dataset ID</label>
            <input className={inputCls} value={datasetId} onChange={e => setDatasetId(e.target.value)} placeholder="my_dataset" required />
          </div>
          <div>
            <label className={labelCls}>Table ID</label>
            <input className={inputCls} value={tableId} onChange={e => setTableId(e.target.value)} placeholder="my_table" required />
          </div>
          {error && <p className="text-red-400 text-xs">{error}</p>}
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2 rounded-lg border border-gray-700 text-sm text-gray-300 hover:bg-gray-800">
              Cancel
            </button>
            <button type="submit" disabled={loading} className="flex-1 px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-500 text-sm text-white font-medium disabled:opacity-50">
              {loading ? 'Adding...' : 'Add Table'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
