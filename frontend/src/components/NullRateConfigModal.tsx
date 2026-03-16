import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { getNullRateColumns, updateNullRateColumns } from '../api/client'
import { X, Plus, Trash2, Key } from 'lucide-react'
import { TableMonitorStatus } from '../types'

interface Props {
  monitor: TableMonitorStatus
  tableId: number
  onClose: () => void
}

export default function NullRateConfigModal({ monitor, tableId, onClose }: Props) {
  const qc = useQueryClient()
  const [saving, setSaving] = useState(false)
  const [customCol, setCustomCol] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['null-rate-columns', monitor.config.id],
    queryFn: () => getNullRateColumns(monitor.config.id),
  })

  const [extraCols, setExtraCols] = useState<string[]>(() => {
    try { return JSON.parse(monitor.config.config_json || '{}').check_columns || [] } catch { return [] }
  })

  const addCol = () => {
    const col = customCol.trim()
    if (col && !extraCols.includes(col)) setExtraCols(prev => [...prev, col])
    setCustomCol('')
  }

  const removeCol = (col: string) => setExtraCols(prev => prev.filter(c => c !== col))

  const save = async () => {
    setSaving(true)
    try {
      await updateNullRateColumns(monitor.config.id, { check_columns: extraCols, use_key_columns: true })
      qc.invalidateQueries({ queryKey: ['table-monitors', tableId] })
      onClose()
    } finally {
      setSaving(false)
    }
  }

  const keyColsFromDup: string[] = data?.key_columns_from_duplicate || []

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-gray-900 border border-gray-700 rounded-2xl w-full max-w-md flex flex-col max-h-[85vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-gray-800 flex-shrink-0">
          <div>
            <h2 className="text-lg font-semibold text-white">Configure Null Check</h2>
            <p className="text-xs text-gray-500 mt-0.5">Null in any checked column = FAIL</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white"><X size={20} /></button>
        </div>

        <div className="overflow-y-auto flex-1 px-6 py-4 space-y-5">
          {/* Key columns (always checked) */}
          <div>
            <p className="text-xs font-medium text-gray-400 mb-2 flex items-center gap-1.5">
              <Key size={12} className="text-blue-400" /> Key columns (always checked)
            </p>
            {isLoading && <p className="text-xs text-gray-500">Loading...</p>}
            {!isLoading && keyColsFromDup.length === 0 && (
              <p className="text-xs text-gray-600">No key columns set — configure them in the Duplicates monitor first.</p>
            )}
            <div className="flex flex-wrap gap-2">
              {keyColsFromDup.map(col => (
                <span key={col} className="text-xs bg-blue-600/20 border border-blue-500/30 text-blue-300 rounded-lg px-2 py-1 font-mono">
                  {col}
                </span>
              ))}
            </div>
          </div>

          {/* Extra columns */}
          <div>
            <p className="text-xs font-medium text-gray-400 mb-2">Additional columns to check</p>
            <div className="flex flex-wrap gap-2 mb-3">
              {extraCols.map(col => (
                <span key={col} className="flex items-center gap-1.5 text-xs bg-gray-800 border border-gray-700 text-gray-300 rounded-lg px-2 py-1 font-mono">
                  {col}
                  <button onClick={() => removeCol(col)} className="text-gray-500 hover:text-red-400">
                    <Trash2 size={11} />
                  </button>
                </span>
              ))}
              {extraCols.length === 0 && <p className="text-xs text-gray-600">None added yet</p>}
            </div>
            <div className="flex gap-2">
              <input
                className="flex-1 bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 font-mono"
                value={customCol}
                onChange={e => setCustomCol(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && addCol()}
                placeholder="column_name"
              />
              <button onClick={addCol} disabled={!customCol.trim()} className="px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg disabled:opacity-40">
                <Plus size={16} />
              </button>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex gap-3 px-6 py-4 border-t border-gray-800 flex-shrink-0">
          <button onClick={onClose} className="flex-1 px-4 py-2 border border-gray-700 rounded-lg text-sm text-gray-300 hover:bg-gray-800">Cancel</button>
          <button onClick={save} disabled={saving} className="flex-1 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-sm font-medium disabled:opacity-40">
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  )
}
