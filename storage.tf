resource "aws_s3_bucket" "corpus" {
  bucket = "fp-lab-corpora-${local.account_suffix}"

  tags = merge(local.common_tags, { Name = "fp-lab-corpora" })
}

resource "aws_s3_bucket_versioning" "corpus" {
  bucket = aws_s3_bucket.corpus.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "corpus" {
  bucket = aws_s3_bucket.corpus.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "corpus" {
  bucket = aws_s3_bucket.corpus.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload vendored configs so instances can pull them at boot via IAM role
resource "aws_s3_object" "sysmon_config" {
  bucket = aws_s3_bucket.corpus.id
  key    = "config/sysmon-config.xml"
  source = "${path.module}/files/sysmon-config.xml"
  etag   = filemd5("${path.module}/files/sysmon-config.xml")
}

resource "aws_s3_object" "ghosts_timeline_workstation" {
  bucket = aws_s3_bucket.corpus.id
  key    = "config/ghosts-timeline-workstation.json"
  source = "${path.module}/files/ghosts-timeline-workstation.json"
  etag   = filemd5("${path.module}/files/ghosts-timeline-workstation.json")
}

resource "aws_s3_object" "ghosts_timeline_server" {
  bucket = aws_s3_bucket.corpus.id
  key    = "config/ghosts-timeline-server.json"
  source = "${path.module}/files/ghosts-timeline-server.json"
  etag   = filemd5("${path.module}/files/ghosts-timeline-server.json")
}

# Vendored agent MSIs pulled from the downloads folder. These embed the
# registration credentials (Action1 customer ID + client cert/key;
# Velociraptor server URL + CA + nonce), so no separate tokens are needed.
resource "aws_s3_object" "action1_agent" {
  bucket      = aws_s3_bucket.corpus.id
  key         = "software/action1_agent.msi"
  source      = "${path.module}/files/action1_agent.msi"
  source_hash = filebase64sha256("${path.module}/files/action1_agent.msi")
}

resource "aws_s3_object" "velociraptor_client" {
  bucket      = aws_s3_bucket.corpus.id
  key         = "software/velociraptor-personal-2026-09-08.msi"
  source      = "${path.module}/files/velociraptor-personal-2026-09-08.msi"
  source_hash = filebase64sha256("${path.module}/files/velociraptor-personal-2026-09-08.msi")
}

resource "aws_s3_bucket_lifecycle_configuration" "corpus" {
  bucket = aws_s3_bucket.corpus.id

  rule {
    id     = "exports-tiering"
    status = "Enabled"

    filter {
      prefix = "exports/"
    }

    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = 365
    }
  }
}
