variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "policy_arn" {
  description = "ARN of the IAM policy to attach (defaults to AmazonECSTaskExecutionRolePolicy)"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}