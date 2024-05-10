# Define the Terraform configuration block
terraform {

  # Define required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"   # Source of the AWS provider
      version = "~> 5.47.0"        # Version constraint for the AWS provider
    }

    random = {
      source  = "hashicorp/random"  # Source of the random provider
      version = "~> 3.6.1"           # Version constraint for the random provider
    }

    tls = {
      source  = "hashicorp/tls"   # Source of the TLS provider
      version = "~> 4.0.5"        # Version constraint for the TLS provider
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"  # Source of the cloudinit provider
      version = "~> 2.3.4"             # Version constraint for the cloudinit provider
    }
  }

  # Specify the required Terraform version
  required_version = "~> 1.3"  # Version constraint for Terraform itself
}
