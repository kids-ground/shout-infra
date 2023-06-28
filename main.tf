# VPC
module "vpc_main" {
  source = "./modules/vpc"
  vpc_name = "${var.project_name}-vpc"

  cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets  
}