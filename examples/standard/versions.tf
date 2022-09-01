#####################################################
# powervs service Module
#####################################################

terraform {
  required_version = ">=1.2"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.44.2"
    }
  }
}