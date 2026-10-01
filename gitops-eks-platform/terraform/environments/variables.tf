variable "aws_region"      { type = string  default = "ap-south-1" }
variable "cluster_name"    { type = string  default = "gitops-eks-platform" }
variable "cluster_version" { type = string  default = "1.30" }
variable "azs"             { type = list(string) default = ["ap-south-1a", "ap-south-1b"] }
variable "tags" {
  type = map(string)
  default = {
    Project   = "gitops-eks-platform"
    ManagedBy = "terraform"
  }
}
