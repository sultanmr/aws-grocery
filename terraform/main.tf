
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
  source = "./modules/vpc"

  name               = "grocery-vpc"
  cidr_block         = "10.0.0.0/16"
  azs                = ["eu-central-1a", "eu-central-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

module "ecr" {
  source               = "./modules/ecr"
  repository_name      = "groceryshop"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
}

module "rds" {
  source                = "./modules/rds"
  cluster_identifier    = "grocerydb"
  engine                = "aurora-postgresql"
  engine_version        = "13.6"
  database_name         = "grocerydb"
  master_username       = "postgres"
  master_password       = random_password.db_password.result
  skip_final_snapshot   = true
  vpc_security_group_ids = [module.security.rds_sg_id]
  subnet_ids            = module.vpc.private_subnets
  publicly_accessible   = true
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name  = "grocery-cluster"
  task_family   = "grocery-task"
  cpu           = 256
  memory        = 512
  execution_role_arn = module.iam.role_arn

  container_name  = "grocery-container"
  container_image = "${module.ecr.repository_url}:latest"
  container_port  = 7080

  environment_variables = [
    {
      name  = "POSTGRES_USER"
      value = "postgres"
    },
    {
      name  = "POSTGRES_HOST"
      value = module.rds.cluster_endpoint
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

  service_name      = "grocery-service"
  desired_count     = 1
  subnets           = module.vpc.public_subnets
  security_groups   = [module.security.ecs_sg_id]
  assign_public_ip  = true
  target_group_arn  = module.alb.target_group_arn
}

resource "aws_lb" "grocery_alb" {
  name               = "grocery-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security.alb_sg_id]
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

module "lex" {
  source = "./modules/lex"

  bot_name = "ProductSearch"
  bot_description = "Bot for searching grocery products"
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

module "security" {
  source = "./modules/security"

  name_prefix     = "grocery"
  vpc_id         = module.vpc.vpc_id
  container_port = 7080
}

module "iam" {
  source = "./modules/iam"

  name_prefix = "grocery"
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
  value = module.lex.bot_name
}