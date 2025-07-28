variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "app_name" {
  description = "AWS_grocery"
  type        = string
  default     = "grocery-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}