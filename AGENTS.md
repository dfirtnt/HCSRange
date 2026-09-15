# fp-lab — Agent Directives

AWS security lab for endpoint telemetry generation and SIEM collection.

## Workflow

1. **Diagnose** with AWS CLI / SSM — inspect state, test hypotheses, verify behavior.
2. **Fix** in Terraform — edit `.tf` files, not live infrastructure.
3. **Verify** — confirm the change is in `.tf` files and `terraform apply` succeeds.
