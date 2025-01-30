
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Filter out local zones, which are not currently supported
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
locals {
  cluster_name = var.cluster_name
  # RFC 1918 IP ranges supported
  remote_network_cidr = "172.16.0.0/16"
  remote_node_cidr    = cidrsubnet(local.remote_network_cidr, 2, 0)
  remote_pod_cidr     = cidrsubnet(local.remote_network_cidr, 2, 1)
}

resource "aws_iam_role" "cluster_admins" {
  name  = "${local.cluster_name}-admins"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS" : data.aws_caller_identity.current.arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cluster_admin" {
  name        = "${local.cluster_name}-admin-policy"
  description = "IAM Policy to provide required permissions to administer this EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:ListFargateProfiles",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:AccessKubernetesApi",
          "eks:ListAddons",
          "eks:DescribeCluster",
          "eks:DescribeAddonVersions",
          "eks:ListClusters",
          "eks:ListIdentityProviderConfigs",
          "iam:ListRoles"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster-admins" {
  role       = aws_iam_role.cluster_admins.name
  policy_arn = aws_iam_policy.cluster_admin.arn

}

# Get the default VPC ID
data "aws_vpc" "default" {
  default = true
}

# Get the subnets for that VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.30.1"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = data.aws_vpc.default.id
  subnet_ids                     = data.aws_subnets.default.ids
  cluster_endpoint_public_access = true
  
  # user that runs this terraform will have access to the cluster
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }
  eks_managed_node_group_defaults = {
    ami_type = var.Nodegroup

  }

  eks_managed_node_groups = {
    one = {
      name = "${local.cluster_name}-ng"

      instance_types = var.InstanceType

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
    }
  }
  cluster_security_group_additional_rules = {
    hybrid-all = {
      cidr_blocks = [local.remote_network_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }
}

data "aws_eks_cluster" "default" {
  name = local.cluster_name
  depends_on = [module.eks.cluster_name]
}

data "aws_eks_cluster_auth" "default" {
  name = local.cluster_name
  depends_on = [module.eks.cluster_name]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#  token                  = data.aws_eks_cluster_auth.default.token
  exec {
  api_version = "client.authentication.k8s.io/v1beta1"
  args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  command     = "aws"
  }
  
}

# This updates the kubeconfig state to add this new cluster automatically so that kubectl will work
resource "null_resource" "kubectl" {
    provisioner "local-exec" {
        command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
    }
}
