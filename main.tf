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