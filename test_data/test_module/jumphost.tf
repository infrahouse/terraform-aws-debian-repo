data "aws_iam_role" "jumphost" {
  name = var.jumphost_role_name
}

data "aws_iam_policy_document" "jumphost-extra" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "jumphost-extra" {
  policy = data.aws_iam_policy_document.jumphost-extra.json
}

resource "aws_iam_role_policy_attachment" "jumphost-extra" {
  policy_arn = aws_iam_policy.jumphost-extra.arn
  role       = data.aws_iam_role.jumphost.name
}
