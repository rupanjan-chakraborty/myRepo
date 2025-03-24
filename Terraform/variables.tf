variable "instances" {
  description = ""
  type = map(object({
    ami           = string
    instance_type = string
    subnet_id     = string
  }))
}

# variable "private-subnet-1_id" {}
# variable "private-subnet-2_id" {}
# variable "public-subnet-1_id" {}
# variable "public-subnet-2_id" {}

# locals {
#   # depends_on = [
#   #   aws_subnet.private-subnet-1, 
#   #   aws_subnet.private-subnet-2, 
#   #   aws_subnet.public-subnet-1, 
#   #   aws_subnet.public-subnet-1
#   #   ]
#   subnet_ids = [
#     data.aws_subnet.public-subnet-1.id,
#     data.aws_subnet.private-subnet-1.id,
#     data.aws_subnet.public-subnet-2.id,
#     data.aws_subnet.private-subnet-2.id,
#   ]
# }