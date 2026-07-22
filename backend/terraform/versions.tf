terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Descomentar y configurar un backend remoto antes de usar en equipo.
  # backend "s3" {
  #   bucket         = "mi-bucket-terraform-state"
  #   key            = "ai-chatbot/auth/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}
