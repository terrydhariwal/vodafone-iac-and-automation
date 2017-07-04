variable "region" {
  default = "us-central1"
}

variable "region_zone" {
  default = "us-central1-f"
}

variable "project_name" {}

variable "account_file_path" {}

variable "gce_ssh_user" {
  default = "terry"
}

variable "gce_ssh_pub_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "gce_ssh_private_key_file" {
  default = "~/.ssh/id_rsa"
}

variable "home_directory" {
  default = "/home/cloudshellpythian"
}
