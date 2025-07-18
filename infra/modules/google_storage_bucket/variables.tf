variable "uniform_bucket_level_access" {
  type = bool
}
variable "name" {
  type = string
}
variable "location" {
  type = string
}
variable "default_labels" {
  type = map(string)
}
variable "enable_object_retention" {
  default = "false"
}
variable "versioning_enabled" {
  default = true
}
variable "lifecycle_rules" {
  type = list(object({
    action = object({
      type          = string
      storage_class = string
    })
    condition = object({
      age                                     = number
      days_since_custom_time                  = number
      days_since_noncurrent_time              = number
      matches_prefix = list(string)
      matches_storage_class = list(string)
      matches_suffix = list(string)
      num_newer_versions                      = number
      send_age_if_zero                        = bool
      send_days_since_custom_time_if_zero     = bool
      send_days_since_noncurrent_time_if_zero = bool
      send_num_newer_versions_if_zero         = bool
      with_state                              = string
    })
  }))
  default = []
}

variable "retention_duration_seconds" {
  type    = number
  default = null
}