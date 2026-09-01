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
  description = "Tailscale hostnames for the three lab nodes."
  value       = ["fp-splunk", "fp-wkstn-01", "fp-srv-01"]
}

output "corpus_bucket_name" {
  description = "Name of the S3 corpus bucket."
  value       = aws_s3_bucket.corpus.bucket
}

output "splunk_web_url" {
  description = "SplunkWeb URL (reachable over tailnet only)."
  value       = "http://fp-splunk:8000"
}

output "splunk_rest_url" {
  description = "Splunk REST API URL (reachable over tailnet only)."
  value       = "https://fp-splunk:8089"
}
