variable "server_port" {
  description = "The port that the server will use to handle HTTP requests (서버가 HTTP 요청을 처리하는 데 사용할 포트)"
  default = 8080
  type = number
  
  validation {
    condition = var.server_port > 0 && var.server_port < 65536
    error_message = "The port number must be between 1-65535"
  }

  sensitive = true
}