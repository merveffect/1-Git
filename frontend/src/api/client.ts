import axios from 'axios'
import type { MonitoredTable, Alert, DashboardStats, TableMonitorStatus } from '../types'

const api = axios.create({ baseURL: '/api' })

export const getTables = () => api.get<MonitoredTable[]>('/tables/').then(r => r.data)
export const addTable = (data: { project_id: string; dataset_id: string; table_id: string; display_name?: string }) =>
  api.post<MonitoredTable>('/tables/', data).then(r => r.data)
export const deleteTable = (id: number) => api.delete(`/tables/${id}`).then(r => r.data)
export const getTableMonitors = (tableId: number) =>
  api.get<TableMonitorStatus[]>(`/tables/${tableId}/monitors`).then(r => r.data)
export const runTableNow = (tableId: number) => api.post(`/tables/${tableId}/run-now`).then(r => r.data)
export const updateMonitorConfig = (configId: number, data: Record<string, unknown>) =>
  api.patch(`/monitors/${configId}`, data).then(r => r.data)
export const suggestKeyColumns = (configId: number) =>
  api.get(`/monitors/${configId}/suggest-keys`).then(r => r.data)
export const getAlerts = (params?: { acknowledged?: boolean; limit?: number }) =>
  api.get<Alert[]>('/alerts/', { params }).then(r => r.data)
export const acknowledgeAlert = (alertId: number) =>
  api.post(`/alerts/${alertId}/acknowledge`).then(r => r.data)
export const getDashboardStats = () => api.get<DashboardStats>('/dashboard').then(r => r.data)
export const getRunHistory = (configId: number) =>
  api.get(`/runs/monitor/${configId}`).then(r => r.data)
export const listGithubRepos = () =>
  api.get('/dbt/github/repos').then(r => r.data)
export const addGithubRepo = (data: { repo_url: string; branch: string }) =>
  api.post('/dbt/github/repos', data).then(r => r.data)
export const syncGithubRepo = (id: number) =>
  api.post(`/dbt/github/repos/${id}/sync`).then(r => r.data)
export const removeGithubRepo = (id: number) =>
  api.delete(`/dbt/github/repos/${id}`).then(r => r.data)
export const setGithubToken = (token: string) =>
  api.post('/dbt/github/token', { token }).then(r => r.data)
export const getGithubTokenStatus = () =>
  api.get('/dbt/github/token-configured').then(r => r.data)
export const addDbtPath = (path: string) =>
  api.post('/dbt/settings', { dbt_project_path: path }).then(r => r.data)
export const removeDbtPath = (path: string) =>
  api.post('/dbt/settings/remove', { dbt_project_path: path }).then(r => r.data)
export const importDbtModels = (projectPath?: string) =>
  api.post('/dbt/import', projectPath ? { project_path: projectPath } : {}).then(r => r.data)
export const getDbtTestHistory = (modelName: string) =>
  api.get(`/dbt/models/${modelName}/test-history`).then(r => r.data)
export const getModelLineage = (modelName: string) =>
  api.get(`/dbt/models/${modelName}/lineage`).then(r => r.data)
export const getDbtRunHistory = (limit = 100) =>
  api.get('/dbt/history', { params: { limit } }).then(r => r.data)
export const getDbtSnapshotResults = (snapshotId: number) =>
  api.get(`/dbt/history/${snapshotId}/results`).then(r => r.data)
export const getAllRuns = (limit = 200) =>
  api.get(`/runs/all`, { params: { limit } }).then(r => r.data)
export const getAllMonitorHistory = (tableId: number) =>
  api.get(`/runs/table/${tableId}/all-monitors`).then(r => r.data)
export const getTablesWithStatus = () =>
  api.get('/tables/with-status').then(r => r.data)
export const listBqDatasets = (project: string) =>
  api.get<{ datasets: string[] }>('/tables/bq/datasets', { params: { project } }).then(r => r.data)
export const listBqTables = (project: string, dataset: string) =>
  api.get<{ tables: string[] }>('/tables/bq/tables', { params: { project, dataset } }).then(r => r.data)
export const getTableUpdateHistory = (tableId: number) =>
  api.get(`/tables/${tableId}/update-history`).then(r => r.data)
export const getPartitionHistory = (tableId: number) =>
  api.get(`/tables/${tableId}/partition-history`).then(r => r.data)
export const getNullRateColumns = (configId: number) =>
  api.get(`/monitors/${configId}/null-rate-columns`).then(r => r.data)
export const updateNullRateColumns = (configId: number, data: Record<string, unknown>) =>
  api.patch(`/monitors/${configId}/null-rate-columns`, data).then(r => r.data)
