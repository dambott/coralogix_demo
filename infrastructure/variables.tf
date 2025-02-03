variable "cluster_name" {
  description = "K8s cluster name"
  type        = string
  default     = "ob2-dev-cx498-uw1"
}

variable "cluster_version" {
  description = "K8s cluster version"
  type        = string
  default     = "1.32"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "Nodegroup" {
  description = "k8s cluster node group"
  type        = string
  default     = "AL2_x86_64"
}

variable "InstanceType" {
  description = "k8s cluster node instance type"
  type        = list
  default     = ["t3.large"]
}

variable "min_size" {
  type        = number
  default     = 3
}

variable "max_size" {
  type        = number
  default     = 3
}

variable "desired_size" {
  type        = number
  default     = 3
}
