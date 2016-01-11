variable "name" {
  default = "vault"
}

variable "environment" {}

variable "user" {
  default = "ubuntu"
}

variable "region" {}

variable "instance_type" {
  default = "t2.small"
}

variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnet_ids" {}
variable "private_subnets" {}
variable "private_ips" {}

variable "ca" {}

variable "consul_acl_register_token" {}
variable "consul_server_security_group_id" {}
variable "consul_agent_security_group_id" {}
variable "consul_encryption" {}

variable "consul_ca" {}
variable "consul_tls_cert" {}
variable "consul_tls_key" {}

variable "consul_acl_datacenter" {}
variable "consul_acl_token" {
  default = ""
}

variable "tls_cert" {}
variable "tls_key" {}

variable "ec2_key_name" {}
variable "private_key" {}

variable "bastion_host" {}
variable "bastion_user" {}
variable "bastion_private_key" {}
variable "bastion_security_group_id" {}

variable "atlas_username" {}
variable "atlas_token" {}
variable "atlas_environment" {}
variable "ami_artifact_version" {
  default = "latest"
}
