data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge_scheduler" {
  name               = "fp_lab_eventbridge_scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "scheduler_ec2" {
  statement {
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]
    resources = concat(
      [aws_instance.splunk_indexer.arn],
      [for ep in aws_instance.windows_endpoint : ep.arn]
    )
  }
}

resource "aws_iam_role_policy" "scheduler_ec2" {
  name   = "fp_lab_scheduler_ec2"
  role   = aws_iam_role.eventbridge_scheduler.id
  policy = data.aws_iam_policy_document.scheduler_ec2.json
}

# ---- Indexer schedules (starts before endpoints, stops after) ----

resource "aws_scheduler_schedule" "indexer_start" {
  count = var.schedule_enabled ? 1 : 0

  name       = "fp-lab-indexer-start"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(30 8 ? * MON-FRI *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    input = jsonencode({
      InstanceIds = [aws_instance.splunk_indexer.id]
    })
  }
}

resource "aws_scheduler_schedule" "indexer_stop" {
  count = var.schedule_enabled ? 1 : 0

  name       = "fp-lab-indexer-stop"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(45 21 ? * MON-FRI *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    input = jsonencode({
      InstanceIds = [aws_instance.splunk_indexer.id]
    })
  }
}

# ---- Windows endpoint schedules ----

resource "aws_scheduler_schedule" "endpoints_start" {
  count = var.schedule_enabled ? 1 : 0

  name       = "fp-lab-endpoints-start"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(45 8 ? * MON-FRI *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    input = jsonencode({
      InstanceIds = [for ep in aws_instance.windows_endpoint : ep.id]
    })
  }
}

resource "aws_scheduler_schedule" "endpoints_stop" {
  count = var.schedule_enabled ? 1 : 0

  name       = "fp-lab-endpoints-stop"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(15 21 ? * MON-FRI *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    input = jsonencode({
      InstanceIds = [for ep in aws_instance.windows_endpoint : ep.id]
    })
  }
}
