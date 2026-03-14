import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { suggestKeyColumns, updateMonitorConfig } from '../api/client'
import { X, Sparkles, CheckCircle, AlertCircle, Plus, Trash2 } from 'lucide-react'
import { TableMonitorStatus } from '../types'

interface Suggestion {
  column: string
  source: string
  rank: number
  uniqueness_ratio?: number
  verified?: boolean
}

interface SuggestResponse {
  suggestions: Suggestion[]
  best_guess: string[]
  all_columns: string[]
}

interface Props {
  monitor: TableMonitorStatus
  tableId: number
  onClose: () => void
}

export default function DuplicateConfigModal({ monitor, tableId, onClose }: Props) {
  const qc = useQueryClient()
  const existing: string[] = JSON.parse(monitor.config.config_json || '{}').key_columns || []
  const [selectedCols, setSelectedCols] = useState<string[]>(existing)
  const [saving, setSaving] = useState(false)
  const [customCol, setCustomCol] = useState('')

  const { data, isLoading } = useQuery<SuggestResponse>({
    queryKey: ['suggest-keys', monitor.config.id],
    queryFn: () => suggestKeyColumns(monitor.config.id),
  })

  const toggle = (col: string) => {
    setSelectedCols(prev =>
      prev.includes(col) ? prev.filter(c => c !== col) : [...prev, col]
    )
  }

  const addCustom = () => {
    const col = customCol.trim()
    if (col && !selectedCols.includes(col)) {
      setSelectedCols(prev => [...prev, col])
    }
    setCustomCol('')
  }

  const applyBestGuess = () => {
    if (data?.best_guess?.length) setSelectedCols(data.best_guess)
  }

  const save = async () => {
    setSaving(true)
    try {
      const currentConfig = JSON.parse(monitor.config.config_json || '{}')
      await updateMonitorConfig(monitor.config.id, {
        config_json: { ...currentConfig, key_columns: selectedCols },
      })
      qc.invalidateQueries({ queryKey: ['table-monitors', tableId] })
      onClose()
    } finally {
      setSaving(false)
    }
  }

  const sourceTag = (s: Suggestion) => {
    if (s.source === 'dbt unique test') return (
      <span className="text-xs bg-orange-500/20 text-orange-400 border border-orange-500/30 rounded px-1.5 py-0.5">dbt unique</span>
    )
    if (s.source === 'name pattern') return (
      <span className="text-xs bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded px-1.5 py-0.5">name match</span>
    )
    return null
  }

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-gray-900 border border-gray-700 rounded-2xl w-full max-w-lg flex flex-col max-h-[90vh]">

        {/* Sticky header */}
        <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-gray-800 flex-shrink-0">
          <div>
            <h2 className="text-lg font-semibold text-white">Configure Duplicate Check</h2>
            <p className="text-xs text-gray-500 mt-0.5">Select columns that together form a unique row key</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white"><X size={20} /></button>
        </div>

        {/* Scrollable body */}
        <div className="overflow-y-auto flex-1 px-6 py-4 space-y-5">

        {/* Auto-detect section */}
        <div className="bg-gray-800 rounded-xl p-4 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-gray-300 flex items-center gap-1.5">
              <Sparkles size={14} className="text-yellow-400" /> Auto-detected candidates
            </span>
            {data?.best_guess?.length ? (
              <button
                onClick={applyBestGuess}
                className="text-xs text-blue-400 hover:text-blue-300"
              >
                Use best guess ({data.best_guess.join(', ')})
              </button>
            ) : null}
          </div>

          {isLoading && <p className="text-xs text-gray-500">Analysing table...</p>}

          {data?.suggestions?.length === 0 && !isLoading && (
            <p className="text-xs text-gray-500">No obvious key columns detected — add them manually below.</p>
          )}

          {data?.suggestions?.map(s => (
            <button
              key={s.column}
              onClick={() => toggle(s.column)}
              className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg border text-left transition-colors ${
                selectedCols.includes(s.column)
                  ? 'border-blue-500 bg-blue-500/10'
                  : 'border-gray-700 hover:border-gray-600 bg-gray-900'
              }`}
            >
              {selectedCols.includes(s.column)
                ? <CheckCircle size={14} className="text-blue-400 flex-shrink-0" />
                : <div className="w-3.5 h-3.5 rounded-full border border-gray-600 flex-shrink-0" />
              }
              <span className="flex-1 text-sm text-gray-200 font-mono">{s.column}</span>
              {sourceTag(s)}
              {s.uniqueness_ratio != null && (
                <span className={`text-xs ${s.verified ? 'text-green-400' : 'text-gray-500'}`}>
                  {s.verified
                    ? <span className="flex items-center gap-1"><CheckCircle size={11} /> {(s.uniqueness_ratio * 100).toFixed(1)}% unique</span>
                    : <span className="flex items-center gap-1"><AlertCircle size={11} /> {(s.uniqueness_ratio * 100).toFixed(1)}% unique</span>
                  }
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Selected columns */}
        <div className="space-y-2">
          <p className="text-xs font-medium text-gray-400">Selected key columns {selectedCols.length > 0 && `(${selectedCols.length})`}</p>
          {selectedCols.length === 0 && (
            <p className="text-xs text-gray-600">None selected — pick from above or add manually</p>
          )}
          <div className="flex flex-wrap gap-2">
            {selectedCols.map(col => (
              <span key={col} className="flex items-center gap-1.5 bg-blue-600/20 border border-blue-500/30 text-blue-300 text-xs rounded-lg px-2 py-1 font-mono">
                {col}
                <button onClick={() => toggle(col)} className="hover:text-white">
                  <Trash2 size={11} />
                </button>
              </span>
            ))}
          </div>
        </div>

        {/* Manual add */}
        <div className="flex gap-2">
          <input
            className="flex-1 bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 font-mono"
            value={customCol}
            onChange={e => setCustomCol(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && addCustom()}
            placeholder="add column manually..."
          />
          <button
            onClick={addCustom}
            disabled={!customCol.trim()}
            className="px-3 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg disabled:opacity-40"
          >
            <Plus size={16} />
          </button>
        </div>

        {/* All columns dropdown hint */}
        {data?.all_columns && data.all_columns.length > 0 && (
          <details className="text-xs text-gray-600">
            <summary className="cursor-pointer hover:text-gray-400">All columns ({data.all_columns.length})</summary>
            <div className="mt-2 flex flex-wrap gap-1.5 max-h-32 overflow-y-auto">
              {data.all_columns.map(col => (
                <button
                  key={col}
                  onClick={() => toggle(col)}
                  className={`font-mono px-2 py-0.5 rounded border text-xs transition-colors ${
                    selectedCols.includes(col)
                      ? 'border-blue-500 text-blue-400 bg-blue-500/10'
                      : 'border-gray-700 text-gray-400 hover:border-gray-500'
                  }`}
                >
                  {col}
                </button>
              ))}
            </div>
          </details>
        )}

        </div>{/* end scrollable body */}

        {/* Sticky footer */}
        <div className="flex gap-3 px-6 py-4 border-t border-gray-800 flex-shrink-0">
          <button onClick={onClose} className="flex-1 px-4 py-2 border border-gray-700 rounded-lg text-sm text-gray-300 hover:bg-gray-800">
            Cancel
          </button>
          <button
            onClick={save}
            disabled={saving || selectedCols.length === 0}
            className="flex-1 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-sm font-medium disabled:opacity-40"
          >
            {saving ? 'Saving...' : 'Save & Run'}
          </button>
        </div>
      </div>
    </div>
  )
}
