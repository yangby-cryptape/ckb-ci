/*
 * Input
 */

variable "access_key" {
  type    = string
}

variable "secret_key" {
  type    = string
}

variable "instances_count" {
  type = number
}

/*
 * Pre-Generated Files
 */

variable "public_key_path" {
  type    = string
  default = "../keys/key.pub"
}

variable "private_key_path" {
  type    = string
  default = "../keys/key"
}

/*
 * Configuration of Machines
 */

variable "prefix" {
  type    = string
  default = "ckb-ci"
}

variable "region" {
  type    = string
  default = "us-west-1"
}

variable "instance_type_bastion" {
  type    = string
  default = "t2.xlarge"
}

variable "instance_type" {
  type    = string
}

variable "username" {
  type    = string
  default = "ubuntu"
}

variable "upload_private_key_path" {
  type    = string
  default = "/home/ubuntu/.ssh/key"
}

variable "private_ip_prefix" {
  type    = string
  default = "10.0.1"
}

variable "private_ip_bastion" {
  type    = string
  default = "10.0.1.10"
}

variable "private_ip_bootnode" {
  type    = string
  default = "10.0.1.11"
}
