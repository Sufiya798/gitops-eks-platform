variable "cluster_name"       { type = string }
variable "cluster_version"    { type = string  default = "1.30" }
variable "subnet_ids"         { type = list(string) }
variable "cluster_role_arn"   { type = string }
variable "node_role_arn"      { type = string }
variable "node_subnet_ids"    { type = list(string) }
variable "instance_types"     { type = list(string) default = ["t3.medium"] }
variable "desired_size"       { type = number default = 2 }
variable "min_size"           { type = number default = 1 }
variable "max_size"           { type = number default = 3 }
variable "tags"               { type = map(string) default = {} }

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = var.tags
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.node_subnet_ids
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = var.tags
}

output "cluster_name"     { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca_data"  { value = aws_eks_cluster.this.certificate_authority[0].data }
output "oidc_issuer"      { value = aws_eks_cluster.this.identity[0].oidc[0].issuer }
