variable "name" {}
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
