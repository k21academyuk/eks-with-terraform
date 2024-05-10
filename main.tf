# Define the AWS provider configuration with the specified region
provider "aws" {
  region = var.region  # Set the region for AWS resources using the value of the "region" variable
}

# Retrieve available AWS availability zones data, filtering out local zones
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Define local variables
locals {
  cluster_name = "k21-eks-cluster"  # Define a local variable for the name of the EKS cluster
}

# Create VPC using Terraform AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"  # Use the AWS VPC module from the Terraform registry
  version = "5.8.1"                           # Use version 5.8.1 of the module

  name = "k21-eks-vpc"  # Name for the VPC

  cidr = "10.0.0.0/16"  # CIDR block for the VPC
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)  # Retrieve the first 3 availability zones

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  # Define private subnets
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]   # Define public subnets

  enable_nat_gateway   = true  # Enable NAT gateway for private subnets
  single_nat_gateway   = true  # Use a single NAT gateway for all subnets
  enable_dns_hostnames = true  # Enable DNS hostnames in the VPC

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1  # Tag public subnets for ELB role
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1  # Tag private subnets for internal ELB role
  }
}

# Create EKS cluster using Terraform AWS EKS module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"  # Use the AWS EKS module from the Terraform registry
  version = "20.8.5"                          # Use version 20.8.5 of the module

  cluster_name    = local.cluster_name        # Name for the EKS cluster
  cluster_version = "1.29"                    # Specify the Kubernetes version for the EKS cluster

  cluster_endpoint_public_access           = true  # Enable public access to the cluster endpoint
  enable_cluster_creator_admin_permissions = true  # Enable admin permissions for cluster creator

  # Define addons for the EKS cluster
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn  # IAM role ARN for the EBS CSI driver
    }
  }

  vpc_id     = module.vpc.vpc_id            # ID of the VPC where the EKS cluster will be created
  subnet_ids = module.vpc.private_subnets   # List of subnet IDs for the EKS cluster

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"  # Default AMI type for managed node groups
  }

  # Define managed node groups for the EKS cluster
  eks_managed_node_groups = {
    one = {
      name = "node-group-1"         # Name for the first node group

      instance_types = ["t3.small"]  # Instance types for the first node group

      min_size     = 1  # Minimum size of the first node group
      max_size     = 3  # Maximum size of the first node group
      desired_size = 2  # Desired size of the first node group
    }

    two = {
      name = "node-group-2"         # Name for the second node group

      instance_types = ["t3.small"]  # Instance types for the second node group

      min_size     = 1  # Minimum size of the second node group
      max_size     = 2  # Maximum size of the second node group
      desired_size = 1  # Desired size of the second node group
    }
  }
}

# Retrieve AWS IAM policy data for EBS CSI driver
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"  # ARN of the IAM policy for EBS CSI driver
}

# Create IAM role for the EBS CSI driver using IAM module
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"  # Use the IAM module from the Terraform registry
  version = "5.39.0"                                                                 # Use version 5.39.0 of the module

  create_role                   = true                                               # Create IAM role for the EBS CSI driver
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"  # Name for the IAM role
  provider_url                  = module.eks.oidc_provider                            # OIDC provider URL
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]            # List of IAM policy ARNs for the role
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]  # Fully qualified subjects for OIDC
}
