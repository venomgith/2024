variable "region" {
  description = "region user in AWS"
  type        = string
  default     = "us-east-1"
}

variable "ami" {
  description = "ami value"
  type        = string
  default     = "ami-0866a3c8686eaeeba"
}

variable "tags" {
  type = map(string)
  default = {
    "Terraform" = "TRUE",
    "Owner"     = "Ellington"
  }
}

variable "aws_access_key" {}

variable "aws_secret_key" {}
