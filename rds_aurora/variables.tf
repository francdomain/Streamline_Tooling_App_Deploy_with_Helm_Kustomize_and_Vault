variable "vpc_id" {
  description = ""
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = ""
  type        = list(string)
}

variable "db_instance_class" {
  description = ""
  type        = string
}
