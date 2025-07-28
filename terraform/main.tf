
## Terraform Scripts

Here's the Terraform configuration to automate this infrastructure:

### main.tf
```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "grocery-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_ecr_repository" "grocery_app" {
  name                 = "groceryshop"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_rds_cluster" "grocery_db" {
  cluster_identifier      = "grocerydb"
  engine                  = "aurora-postgresql"
  engine_version          = "13.6"
  database_name           = "grocerydb"
  master_username         = "postgres"
  master_password         = random_password.db_password.result
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  publicly_accessible     = true
}

resource "aws_db_subnet_group" "default" {
  name       = "grocery-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_ecs_cluster" "grocery_cluster" {
  name = "grocery-cluster"
}

resource "aws_ecs_task_definition" "grocery_task" {
  family                   = "grocery-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "grocery-container"
    image     = "${aws_ecr_repository.grocery_app.repository_url}:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 7080
      hostPort      = 7080
      protocol      = "tcp"
      appProtocol   = "http"
    }]
    environment = [
      {
        name  = "POSTGRES_USER"
        value = "postgres"
      },
      {
        name  = "POSTGRES_HOST"
        value = aws_rds_cluster.grocery_db.endpoint
      },
      {
        name  = "POSTGRES_PASSWORD"
        value = random_password.db_password.result
      },
      {
        name  = "POSTGRES_DB"
        value = "grocerydb"
      }
    ]
  }])
}

resource "aws_ecs_service" "grocery_service" {
  name            = "grocery-service"
  cluster         = aws_ecs_cluster.grocery_cluster.id
  task_definition = aws_ecs_task_definition.grocery_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grocery_tg.arn
    container_name   = "grocery-container"
    container_port   = 7080
  }

  depends_on = [aws_lb_listener.grocery_listener]
}

resource "aws_lb" "grocery_alb" {
  name               = "grocery-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "grocery_tg" {
  name        = "grocery-tg"
  port        = 7080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "grocery_listener" {
  load_balancer_arn = aws_lb.grocery_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grocery_tg.arn
  }
}

resource "aws_lex_bot" "product_search" {
  name                        = "ProductSearch"
  description                 = "Bot for searching grocery products"
  child_directed              = false
  process_behavior            = "BUILD"
  idle_session_ttl_in_seconds = 300

  abort_statement {
    message {
      content      = "Sorry, I couldn't understand. Please try again."
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.product_search.name
    intent_version = "$LATEST"
  }

  clarification_prompt {
    max_attempts = 2
    message {
      content      = "I didn't understand you. Could you please rephrase?"
      content_type = "PlainText"
    }
  }
}

resource "aws_lex_intent" "product_search" {
  name = "ProductSearch"
  description = "Intent for searching products"

  sample_utterances = [
    "I'm looking for {productsName}",
    "Find me {productsName}",
    "Show me {productsName}",
    "Do you have {productsName}",
    "Search for {productsName}",
    "do you sell apples"
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }

  slot {
    name         = "productsName"
    description  = "The name of the product to search for"
    slot_constraint = "Required"
    slot_type    = "AMAZON.Fruit"
    value_elicitation_prompt {
      max_attempts = 2
      message {
        content      = "What product would you like to search for?"
        content_type = "PlainText"
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/grocery-app"
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_alarm" {
  alarm_name          = "grocery-app-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This alarm monitors ECS CPU utilization"
  dimensions = {
    ClusterName = aws_ecs_cluster.grocery_cluster.name
    ServiceName = aws_ecs_service.grocery_service.name
  }
}

resource "aws_security_group" "alb" {
  name        = "grocery-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  name        = "grocery-ecs-sg"
  description = "Allow traffic from ALB to ECS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 7080
    to_port         = 7080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "grocery-rds-sg"
  description = "Allow traffic from ECS to RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

output "alb_dns_name" {
  value = aws_lb.grocery_alb.dns_name
}

output "rds_endpoint" {
  value = aws_rds_cluster.grocery_db.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.grocery_app.repository_url
}

output "lex_bot_name" {
  value = aws_lex_bot.product_search.name
}