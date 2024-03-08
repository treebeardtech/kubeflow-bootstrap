variable "password" {
  sensitive   = true
  description = "password for user@example.com"
}

variable "host" {
}

variable "cert_email_owner" {
}

variable "hosted_zone_id" {
}

variable "aws_region" {
  description = "AWS region to launch servers."
}

variable "aws_profile" {
  description = "AWS profile to use for authentication."
}

variable "enable_treebeardkf" {
  description = "Enable Treebeard KF"
  type        = bool
  default     = false
}
