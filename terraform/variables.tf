variable "project_name" {
  description = "Name used for tagging and resource prefixes"
  type        = string
  default     = "wanderlust"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.large"
}

variable "ssh_key_name" {
  description = "Name of an EXISTING EC2 key pair used for the Jenkins host"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach Jenkins (22/8080). Set this to your own IP, e.g. 1.2.3.4/32"
  type        = string
}
