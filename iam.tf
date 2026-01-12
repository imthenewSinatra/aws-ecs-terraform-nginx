resource "aws_iam_role" "ecs_agent" {
  name = "ecs-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_agent_attach" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent_profile" {
  name = "ecs-agent-profile"
  role = aws_iam_role.ecs_agent.name
}

# Permissão para o agente do ECS criar e enviar logs
resource "aws_iam_role_policy_attachment" "ecs_logs_attach" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}