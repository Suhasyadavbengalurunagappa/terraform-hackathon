terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-hachathon"   # replace with your bucket
    key            = "dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
