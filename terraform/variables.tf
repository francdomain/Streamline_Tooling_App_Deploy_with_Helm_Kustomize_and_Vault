variable "tags" {
  type = map(any)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
