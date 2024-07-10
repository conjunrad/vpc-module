variable "main_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidr" {
  default = [
    "10.0.10.0/24",
    "10.0.20.0/24"
  ]
}

variable "general_tags" {
  type = map(any)
  default = {
    Environment = "dev"
    Owner       = "Roman Tarasenko"
  }
}
