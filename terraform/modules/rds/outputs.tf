output "cluster_endpoint" {
  description = "The DNS address of the RDS cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_identifier" {
  description = "The RDS cluster identifier"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "database_name" {
  description = "The database name"
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "The master username"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}