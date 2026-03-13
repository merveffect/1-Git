import { useQuery } from '@tanstack/react-query'
import { getAlerts } from '../api/client'

export const useAlerts = (params?: { acknowledged?: boolean; limit?: number }) =>
  useQuery({ queryKey: ['alerts', params], queryFn: () => getAlerts(params), refetchInterval: 15000 })
