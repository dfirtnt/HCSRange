# Ubuntu 22.04 LTS amd64 — resolved via SSM, no hardcoded AMI ID.
# Splunk Enterprise is x86_64-only (no Linux ARM64 build on Splunk's CDN).
data "aws_ssm_parameter" "ubuntu_amd64_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_instance" "splunk_indexer" {
  ami                    = data.aws_ssm_parameter.ubuntu_amd64_ami.value
  instance_type          = var.indexer_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.fp_lab_egress_only.id]
  iam_instance_profile   = aws_iam_instance_profile.fp_lab_node.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata/splunk_indexer.sh.tftpl", {
    tailscale_auth_key    = var.tailscale_auth_key
    splunk_admin_password = var.splunk_admin_password
    splunk_hec_token      = var.splunk_hec_token
  })

  user_data_replace_on_change = false

  tags = merge(local.common_tags, { Name = "fp-splunk" })
}

# Separate data volume so indexes survive instance replacement
resource "aws_ebs_volume" "splunk_data" {
  availability_zone = "${var.aws_region}a"
  size              = 60
  type              = "gp3"

  # Guard the index data: `terraform destroy` (and any replace of this volume)
  # will fail until this block is removed. See README "Destroy".
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.common_tags, { Name = "fp-splunk-data" })
}

resource "aws_volume_attachment" "splunk_data" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.splunk_data.id
  instance_id  = aws_instance.splunk_indexer.id
  force_detach = false
}
