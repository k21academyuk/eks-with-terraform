# Define a variable named "region"
variable "region" {
  description = "AWS region"  # Description of the variable
  type        = string         # Type constraint for the variable (string)
  default     = "us-east-1"   # Default value for the variable
}
