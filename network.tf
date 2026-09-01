resource "aws_vpc" "fp_lab" {
  cidr_block           = "10.77.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.fp_lab.id
  cidr_block              = "10.77.0.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-public" })
}

resource "aws_internet_gateway" "fp_lab" {
  vpc_id = aws_vpc.fp_lab.id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.fp_lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fp_lab.id
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rt-public" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Egress-only: no ingress rules. Public IPs are used only for outbound traffic
# (Tailscale, Splunk-to-S3, updates, GHOSTS browsing). SG exposes no listening surface.
resource "aws_security_group" "fp_lab_egress_only" {
  name        = "fp_lab_egress_only"
  description = "Egress-only: all outbound allowed, no inbound rules."
  vpc_id      = aws_vpc.fp_lab.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-egress-only" })
}
