# VPC
module "vpc_main" {
  source = "./modules/vpc"
  vpc_name = "${var.project_name}-vpc"

  cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets  
}

# ECR
module "ecr" {
  source = "./modules/ecr"
  name = "${var.project_name}-api-server-ecr"
}

# EC2 - (SG, Profile, Key, Instance, EIP)
module "ec2_sg" {
  source = "./modules/security_group"
  name = "${var.project_name}-public-ec2-sg"
  vpc_id = module.vpc_main.vpc_id
  inbound_rules = var.ec2_inbound_rule
  outbound_rules = var.outbound_rule
}

module "ec2_profile" {
  source = "./modules/ec2/public/profile"
  project_name = var.project_name
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.key_pair_name}"
  public_key = file("~/.ssh/${var.key_pair_name}.pub")
}

resource "aws_instance" "free_tier_ec2" {
  ami = "ami-0e4a9ad2eb120e054" # Amazon Linux2 ami(ap-northeast-2)
  instance_type = "t2.micro" # 프리티어

  subnet_id = module.vpc_main.public_subnets_ids[0]
  vpc_security_group_ids = [
    module.ec2_sg.id
  ]

  key_name = aws_key_pair.ec2_key_pair.key_name
  user_data = file("./modules/ec2/public/user_data.sh")
  iam_instance_profile = module.ec2_profile.ec2_profile

  tags = {
    Nmae = "${var.project_name}-public-ec2"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "public_ec2_eip" {
  allocation_id = aws_eip.eip.id
  instance_id = aws_instance.free_tier_ec2.id
}

# RDS (SG, rds)
module "db_sg" {
  source = "./modules/security_group"
  name = "${var.project_name}-rds-sg"
  vpc_id = module.vpc_main.vpc_id
  inbound_rules = var.db_inbound_rule
  outbound_rules = var.outbound_rule
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc_main.private_subnets_ids
}

resource "aws_db_instance" "db" {
  identifier = "${var.project_name}-rds"
  vpc_security_group_ids = [ module.db_sg.id ]
  availability_zone = var.az_names[0]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  
  engine = "mysql"
  engine_version = "8.0.32"
  instance_class = "db.t4g.micro"
  
  db_name = "${var.project_name}"
  username             = var.db_username
  password             = var.db_password

  max_allocated_storage = 1000
  allocated_storage = 20
  backup_retention_period = 5 # 백업본 저장기간
  ca_cert_identifier = "rds-ca-2019"
  storage_encrypted = true

  copy_tags_to_snapshot = true
  skip_final_snapshot = true
}

# # S3

# # ACM

# # Route53

# # API Gateway