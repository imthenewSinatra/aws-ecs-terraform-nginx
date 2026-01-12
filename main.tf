provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Rede Básica
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "pub" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

# 1. Criando a Tabela de Rotas
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# 2. Associar a Tabela de Rotas à Subnet
resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.pub_rt.id
}

# Security Group
resource "aws_security_group" "sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  # Entrada: Permite acesso ao Nginx
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída: OBRIGATÓRIO para o ECS baixar o Docker
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Cluster ECS
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"
}

# Instância EC2 que rodará os containers
resource "aws_instance" "ecs_node" {
  ami                    = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type          = var.instance_type
  availability_zone      = "us-east-1a"
  iam_instance_profile   = aws_iam_instance_profile.ecs_agent_profile.name
  subnet_id              = aws_subnet.pub.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config
              EOF

  tags = { Name = "ECS-Worker-Node" }
}

# Definição do Container (Task)
resource "aws_ecs_task_definition" "task" {
  family = "nginx-task"
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/nginx-logs"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}

resource "aws_ecr_repository" "nginx_repo" {
  name                 = "nginx-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Serviço ECS para manter o container rodando
resource "aws_ecs_service" "service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "EC2"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/nginx-logs"
  retention_in_days = 7
}