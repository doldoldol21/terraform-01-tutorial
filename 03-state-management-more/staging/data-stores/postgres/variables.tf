# root
variable "username" {
  description = "The database username."
  type = string
  sensitive = true
}

# test12345
variable "password" {
  description = "The database password."
  type = string
  sensitive = true
}