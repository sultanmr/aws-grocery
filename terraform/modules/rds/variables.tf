variable "cluster_identifier" {
  description = "The cluster identifier for the RDS cluster"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "The database engine version"
  type        = string
  default     = "13.6"
}

variable "database_name" {
  description = "Name for the database"
  type        = string
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "master_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate with the cluster"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs to use for the DB subnet group"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the DB should be publicly accessible"
  type        = bool
  default     = false
}