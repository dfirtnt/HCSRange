variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name (IAM Identity Center SSO profile)."
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources."
}

variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "Reusable Tailscale auth key scoped to tag:fp-lab (90-day, minted in Tailscale admin console)."
}

variable "splunk_admin_password" {
  type        = string
  sensitive   = true
  description = "Splunk Enterprise admin password. Operator-chosen; rotate in-app after first login."
}

variable "splunk_hec_token" {
  type        = string
  sensitive   = true
  description = "Splunk HEC token (operator-chosen UUID)."
}

variable "windows_admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the built-in Administrator account on Windows endpoints. Used for RDP access."
}

variable "alert_email" {
  type        = string
  description = "Email address for AWS Budgets cost alert notifications."
}

variable "endpoint_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Instance type for the two Windows telemetry endpoints. Bump to t3.large only if GHOSTS activity visibly stalls."
}

variable "indexer_instance_type" {
  type        = string
  default     = "t4g.large"
  description = "Instance type for the Splunk indexer (Graviton; Splunk ships aarch64 Linux builds)."
}

variable "endpoints_use_spot" {
  type        = bool
  default     = true
  description = "Use persistent spot requests for Windows endpoints. Set false for on-demand if spot capacity misbehaves."
}

variable "schedule_enabled" {
  type        = bool
  default     = true
  description = "Enable EventBridge Scheduler start/stop rules. Set false to keep all instances stopped."
}
