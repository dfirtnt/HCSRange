# Windows Server 2022 — resolved via SSM, no hardcoded AMI ID
data "aws_ssm_parameter" "windows_2022_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

locals {
  endpoints = {
    "fp-wkstn-01" = { profile = "workstation" }
    "fp-srv-01"   = { profile = "server" }
  }
}

resource "aws_instance" "windows_endpoint" {
  for_each = local.endpoints

  ami                    = data.aws_ssm_parameter.windows_2022_ami.value
  instance_type          = var.endpoint_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.fp_lab_egress_only.id]
  iam_instance_profile   = aws_iam_instance_profile.fp_lab_node.name

  dynamic "instance_market_options" {
    for_each = var.endpoints_use_spot ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        spot_instance_type             = "persistent"
        instance_interruption_behavior = "stop"
      }
    }
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 60
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata/windows_endpoint.ps1.tftpl", {
    tailscale_auth_key     = var.tailscale_auth_key
    hostname               = each.key
    profile                = each.value.profile
    splunk_hec_token       = var.splunk_hec_token
    account_suffix         = local.account_suffix
    windows_admin_password = var.windows_admin_password
    # MagicDNS hostname of the live indexer (indexer is created first in this
    # module, so its instance ID is known when the endpoint user data renders).
    indexer_tailnet_hostname = "fp-splunk-${substr(aws_instance.splunk_indexer.id, 2, 6)}"
  })

  user_data_replace_on_change = false

  tags = merge(local.common_tags, { Name = each.key })
}
