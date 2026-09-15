locals {
  # Tailnet hostnames are suffixed with the instance ID (e.g. fp-splunk-1a2b3c)
  # so fresh instances never collide with stale tailnet nodes from prior deploys.
  indexer_tailnet_name = "fp-splunk-${substr(replace(aws_instance.splunk_indexer.id, "i-", ""), 0, 6)}"
  wkstn_tailnet_name   = "fp-wkstn-01-${substr(replace(aws_instance.windows_endpoint["fp-wkstn-01"].id, "i-", ""), 0, 6)}"
  srv_tailnet_name     = "fp-srv-01-${substr(replace(aws_instance.windows_endpoint["fp-srv-01"].id, "i-", ""), 0, 6)}"
}

output "indexer_instance_id" {
  description = "EC2 instance ID of the Splunk indexer."
  value       = aws_instance.splunk_indexer.id
}

output "endpoint_instance_ids" {
  description = "EC2 instance IDs of the two Windows telemetry endpoints."
  value = {
    fp-wkstn-01 = aws_instance.windows_endpoint["fp-wkstn-01"].id
    fp-srv-01   = aws_instance.windows_endpoint["fp-srv-01"].id
  }
}

output "tailnet_hostnames" {
  description = "Tailscale hostnames for the three lab nodes (suffixed with instance ID to avoid stale-node collisions)."
  value       = [local.indexer_tailnet_name, local.wkstn_tailnet_name, local.srv_tailnet_name]
}

output "corpus_bucket_name" {
  description = "Name of the S3 corpus bucket."
  value       = aws_s3_bucket.corpus.bucket
}

output "splunk_web_url" {
  description = "SplunkWeb URL (reachable over tailnet only)."
  value       = "http://${local.indexer_tailnet_name}:8000"
}

output "splunk_rest_url" {
  description = "Splunk REST API URL (reachable over tailnet only)."
  value       = "https://${local.indexer_tailnet_name}:8089"
}