terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.31.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.7.0" }
  }
}
provider "aws" { region = "eu-west-1" }
