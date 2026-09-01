data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fp_lab_node" {
  name               = "fp_lab_node"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.fp_lab_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "corpus_bucket_access" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.corpus.arn,
      "${aws_s3_bucket.corpus.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "corpus_bucket_access" {
  name   = "fp_lab_corpus_bucket_access"
  policy = data.aws_iam_policy_document.corpus_bucket_access.json
}

resource "aws_iam_role_policy_attachment" "corpus_bucket" {
  role       = aws_iam_role.fp_lab_node.name
  policy_arn = aws_iam_policy.corpus_bucket_access.arn
}

resource "aws_iam_instance_profile" "fp_lab_node" {
  name = "fp_lab_node"
  role = aws_iam_role.fp_lab_node.name
}
