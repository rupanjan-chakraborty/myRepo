variable "instances" {
  description = ""
  type = map(object({
    ami           = string
    instance_type = string
  }))
}