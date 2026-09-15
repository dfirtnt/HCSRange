# FP Lab — Terraform Runbook

AWS telemetry factory: Splunk indexer + 2 Windows endpoints generating benign Sysmon telemetry, business-hours scheduled.

## Cost

| Item | Est. $/mo |
|---|---|
| Indexer t4g.large @ ~38% duty + 90 GB gp3 | ~$26 |
| 2× Windows t3.medium spot @ 37% duty | ~$24 |
| 2× 60 GB gp3 root | ~$10 |
| S3 + data transfer + EventBridge | ~$5 |
| **Total** | **~$65/mo** |

Budget alert fires at 50% and 75% of $150/mo (hard ceiling).

## Prerequisites

1. **AWS credentials** — `aws configure sso`, note the profile name.
2. **Tailscale** — create tag `tag:fp-lab` in admin console ACLs (Tag owners). The policy already grants `tag:fp-lab ⇄ tag:fp-lab` and `autogroup:member → tag:fp-lab`. Mint a reusable auth key tagged `tag:fp-lab` with **Pre-approved** enabled (Keys → Generate auth key → Pre-approved) so tagged nodes self-approve on rebuild and avoid per-rebuild console approval.
3. **Splunk** — choose an admin password and a HEC token (any UUID).
4. **tfvars** — create `terraform.auto.tfvars` (gitignored):

```hcl
aws_profile            = "your-sso-profile"
tailscale_auth_key     = "tskey-auth-..."
splunk_admin_password  = "ChangeMe123!"
splunk_hec_token       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
alert_email            = "you@example.com"
windows_admin_password = "YourWindowsPassword!"
```

5. **Splunk SHA512** — before applying, get the aarch64 .deb SHA512 from the [Splunk download page](https://www.splunk.com/en_us/download/splunk-enterprise.html) and update `SPLUNK_SHA512` in `userdata/splunk_indexer.sh.tftpl`.

6. **Splunk UF SHA256 + Sysmon SHA256** — similarly update the hash placeholders in `userdata/windows_endpoint.ps1.tftpl`.

7. **sysmon-config.xml** — the vendored config in `files/sysmon-config.xml` is a baseline. To regenerate from sysmon-modular:
   ```
   git clone https://github.com/olafhartong/sysmon-modular && cd sysmon-modular
   . .\Merge-SysmonXml.ps1
   Merge-AllSysmonXml -Path .\* -AsString | Out-File ../infra/fp-lab/files/sysmon-config.xml
   ```

## Apply

```bash
cd infra/fp-lab
terraform init
terraform plan
terraform apply
```

Apply takes ~5 min. Instances finish bootstrapping 10–15 min after apply completes.

## Verify

```bash
# Tailnet hostnames are suffixed with the instance ID; resolve them from terraform
tailscale status | grep -E "fp-splunk-|fp-wkstn-01-|fp-srv-01-"

# SplunkWeb reachable over tailnet
curl -k https://$(terraform output -raw splunk_rest_url | sed 's#https://##')/services/server/info -u admin:YOUR_PASSWORD | jq .

# Sysmon events flowing (run ~30 min after endpoint boot)
# In Splunk: index=fp_lab_wineventlog EventCode=1 | head 10

# Security check — all ports filtered from outside tailnet
nmap -Pn <indexer-public-ip>
```

## Off-hours backtest

Instances park on the EventBridge schedule. To run a backtest outside business hours:

```bash
# Start all three
aws ec2 start-instances --instance-ids \
  $(terraform output -json endpoint_instance_ids | jq -r '.[]') \
  $(terraform output -raw indexer_instance_id) \
  --region us-east-1 --profile your-sso-profile

# The next scheduled stop (21:15 ET for endpoints, 21:45 ET for indexer) re-parks them.
```

## Destroy

```caution
The Splunk data EBS volume has prevent_destroy = true.
Remove that lifecycle block before running destroy if you intend to delete it.
```

```bash
terraform destroy
```

## State backend migration (follow-up)

Once the S3 bucket exists, add to `versions.tf`:

```hcl
backend "s3" {
  bucket         = "fp-lab-corpora-<account-suffix>"
  key            = "terraform/fp-lab.tfstate"
  region         = "us-east-1"
  dynamodb_table = "fp-lab-tf-lock"
  encrypt        = true
}
```

Create the DynamoDB table (`fp-lab-tf-lock`, partition key `LockID`, PAY_PER_REQUEST) then `terraform init -migrate-state`.
