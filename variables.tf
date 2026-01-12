variable "region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "cloud-stack-production"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "budget_emails" {
  description = "List of emails to receive budget notifications"
  type        = list(string)
  default     = ["your-main@email.com", "another-one@backup.com"]
}