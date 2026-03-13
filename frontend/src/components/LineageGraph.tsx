import { useQuery } from '@tanstack/react-query'
import { getModelLineage } from '../api/client'
import {
  ReactFlow,
  Background,
  Controls,
  type Node,
  type Edge,
  Position,
  BackgroundVariant,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'

interface LineageNode {
  unique_id: string
  name: string
  resource_type: string | null
}

interface LineageData {
  upstream: LineageNode[]
  downstream: LineageNode[]
}

const TYPE_COLOR: Record<string, { bg: string; border: string; text: string }> = {
  model:   { bg: '#1e3a5f', border: '#3b82f6', text: '#93c5fd' },
  source:  { bg: '#1a3a2a', border: '#22c55e', text: '#86efac' },
  seed:    { bg: '#2d2a1a', border: '#eab308', text: '#fde047' },
  test:    { bg: '#3a1a2a', border: '#ec4899', text: '#f9a8d4' },
  current: { bg: '#1e2a4a', border: '#6366f1', text: '#c7d2fe' },
}

function buildGraph(modelName: string, data: LineageData): { nodes: Node[]; edges: Edge[] } {
  const nodes: Node[] = []
  const edges: Edge[] = []

  const COL_X = { upstream: 0, current: 320, downstream: 640 }
  const ROW_H = 64

  // Current model node (center)
  nodes.push({
    id: 'current',
    position: { x: COL_X.current, y: 0 },
    sourcePosition: Position.Right,
    targetPosition: Position.Left,
    data: { label: modelName },
    style: {
      background: TYPE_COLOR.current.bg,
      border: `2px solid ${TYPE_COLOR.current.border}`,
      color: TYPE_COLOR.current.text,
      borderRadius: 10,
      padding: '8px 14px',
      fontSize: 13,
      fontWeight: 600,
      minWidth: 160,
      textAlign: 'center' as const,
      boxShadow: `0 0 12px ${TYPE_COLOR.current.border}55`,
    },
  })

  // Upstream nodes (left column)
  const upstreamOffset = -(((data.upstream.length - 1) * ROW_H) / 2)
  data.upstream.forEach((n, i) => {
    const rtype = n.resource_type || 'model'
    const c = TYPE_COLOR[rtype] || TYPE_COLOR.model
    nodes.push({
      id: n.unique_id,
      position: { x: COL_X.upstream, y: upstreamOffset + i * ROW_H },
      sourcePosition: Position.Right,
      targetPosition: Position.Left,
      data: { label: n.name },
      style: {
        background: c.bg,
        border: `1.5px solid ${c.border}`,
        color: c.text,
        borderRadius: 8,
        padding: '6px 12px',
        fontSize: 12,
        minWidth: 140,
        textAlign: 'center' as const,
      },
    })
    edges.push({
      id: `e-${n.unique_id}-current`,
      source: n.unique_id,
      target: 'current',
      style: { stroke: '#374151', strokeWidth: 1.5 },
      animated: false,
    })
  })

  // Downstream nodes (right column)
  const downstreamOffset = -(((data.downstream.length - 1) * ROW_H) / 2)
  data.downstream.forEach((n, i) => {
    const rtype = n.resource_type || 'model'
    const c = TYPE_COLOR[rtype] || TYPE_COLOR.model
    nodes.push({
      id: n.unique_id,
      position: { x: COL_X.downstream, y: downstreamOffset + i * ROW_H },
      sourcePosition: Position.Right,
      targetPosition: Position.Left,
      data: { label: n.name },
      style: {
        background: c.bg,
        border: `1.5px solid ${c.border}`,
        color: c.text,
        borderRadius: 8,
        padding: '6px 12px',
        fontSize: 12,
        minWidth: 140,
        textAlign: 'center' as const,
      },
    })
    edges.push({
      id: `e-current-${n.unique_id}`,
      source: 'current',
      target: n.unique_id,
      style: { stroke: '#374151', strokeWidth: 1.5 },
      animated: false,
    })
  })

  return { nodes, edges }
}

interface Props {
  modelName: string
}

export default function LineageGraph({ modelName }: Props) {
  const { data, isLoading, isError } = useQuery<LineageData>({
    queryKey: ['lineage', modelName],
    queryFn: () => getModelLineage(modelName),
    enabled: !!modelName,
  })

  if (isLoading) return (
    <div className="h-48 flex items-center justify-center text-gray-500 text-sm">
      Loading lineage...
    </div>
  )

  if (isError || !data) return (
    <div className="h-48 flex items-center justify-center text-gray-600 text-sm">
      Lineage unavailable — ensure dbt project path is set in Settings
    </div>
  )

  const hasLineage = data.upstream.length > 0 || data.downstream.length > 0

  if (!hasLineage) return (
    <div className="h-24 flex items-center justify-center text-gray-600 text-sm">
      No upstream or downstream dependencies found for <span className="text-gray-400 font-mono ml-1">{modelName}</span>
    </div>
  )

  const { nodes, edges } = buildGraph(modelName, data)

  // Legend
  const legendItems = [
    { label: 'Current model', ...TYPE_COLOR.current },
    { label: 'Model',  ...TYPE_COLOR.model },
    { label: 'Source', ...TYPE_COLOR.source },
    { label: 'Seed',   ...TYPE_COLOR.seed },
  ]

  return (
    <div className="space-y-2">
      {/* Legend */}
      <div className="flex items-center gap-4 px-1">
        {legendItems.map(item => (
          <span key={item.label} className="flex items-center gap-1.5 text-xs text-gray-500">
            <span className="w-3 h-3 rounded" style={{ background: item.bg, border: `1.5px solid ${item.border}` }} />
            {item.label}
          </span>
        ))}
        <span className="ml-auto text-xs text-gray-600">
          {data.upstream.length} upstream · {data.downstream.length} downstream
        </span>
      </div>

      {/* Graph */}
      <div className="rounded-xl overflow-hidden border border-gray-800" style={{ height: 280 }}>
        <ReactFlow
          nodes={nodes}
          edges={edges}
          fitView
          fitViewOptions={{ padding: 0.3 }}
          nodesDraggable={false}
          nodesConnectable={false}
          elementsSelectable={false}
          zoomOnScroll={false}
          panOnScroll={true}
          proOptions={{ hideAttribution: true }}
          style={{ background: '#0a0f1a' }}
        >
          <Background color="#1f2937" variant={BackgroundVariant.Dots} gap={20} size={1} />
          <Controls showInteractive={false} style={{ background: '#111827', border: '1px solid #374151' }} />
        </ReactFlow>
      </div>
    </div>
  )
}
