variable "vpc_cidr" {
  default = "10.0.0.0/16"

}

variable "aws_subnet_public" {
  default = "10.0.1.0/24"

}

variable "aws_subnet_private" {
  default = "10.0.2.0/24"

}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.medium"
}
