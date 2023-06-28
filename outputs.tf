output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_arn" {
  value = module.ecr.arn
}

output "ec2_ip" {
  value = aws_eip.eip.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "s3_domain" {
  value = module.s3.domain_name
}