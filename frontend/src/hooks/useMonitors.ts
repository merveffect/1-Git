import { useQuery } from '@tanstack/react-query'
import { getTables, getTableMonitors, getDashboardStats } from '../api/client'

export const useTables = () =>
  useQuery({ queryKey: ['tables'], queryFn: getTables, refetchInterval: 30000 })

export const useTableMonitors = (tableId: number) =>
  useQuery({ queryKey: ['table-monitors', tableId], queryFn: () => getTableMonitors(tableId), refetchInterval: 15000 })

export const useDashboard = () =>
  useQuery({ queryKey: ['dashboard'], queryFn: getDashboardStats, refetchInterval: 30000 })
