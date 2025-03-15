resource "aws_instance" "servers" {
  for_each      = var.instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
  tags = {
    Name = "${each.key}"
  }
  root_block_device {
    volume_size           = 20    # Size in GB, adjust as needed
    volume_type           = "gp2" # General Purpose SSD
    delete_on_termination = true  # Optional: delete the volume when the instance is terminated
  }
}
