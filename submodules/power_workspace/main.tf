#####################################################
# IBM Cloud PowerVS Resource Configuration
#####################################################

locals {
  service_type = "power-iaas"
  plan         = "power-virtual-server-group"
}

data "ibm_resource_group" "resource_group_ds" {
  name = var.powervs_resource_group_name
}

resource "ibm_resource_instance" "powervs_workspace" {
  name              = var.powervs_workspace_name
  service           = local.service_type
  plan              = local.plan
  location          = var.powervs_zone
  resource_group_id = data.ibm_resource_group.resource_group_ds.id
  tags              = (var.tags != null ? var.tags : [])

  timeouts {
    create = "6m"
    update = "5m"
    delete = "10m"
  }
}

#####################################################
# Create IBM Cloud PowerVS SSH Key
#####################################################

resource "ibm_pi_key" "ssh_key" {
  pi_cloud_instance_id = ibm_resource_instance.powervs_workspace.guid
  pi_key_name          = var.powervs_sshkey_name
  pi_ssh_key           = var.ssh_public_key
}

#####################################################
# Create Public and Private Subnets
#####################################################

resource "ibm_pi_network" "management_network" {
  pi_cloud_instance_id = ibm_resource_instance.powervs_workspace.guid
  pi_network_name      = var.powervs_management_network["name"]
  pi_cidr              = var.powervs_management_network["cidr"]
  pi_dns               = ["127.0.0.1"]
  pi_network_type      = "vlan"
  pi_network_jumbo     = true
}

resource "ibm_pi_network" "backup_network" {
  depends_on           = [ibm_pi_network.management_network]
  pi_cloud_instance_id = ibm_resource_instance.powervs_workspace.guid
  pi_network_name      = var.powervs_backup_network["name"]
  pi_cidr              = var.powervs_backup_network["cidr"]
  pi_dns               = ["127.0.0.1"]
  pi_network_type      = "vlan"
  pi_network_jumbo     = true
}

#####################################################
# Import Catalog Images
#####################################################

data "ibm_pi_catalog_images" "catalog_images_ds" {
  sap                  = true
  pi_cloud_instance_id = ibm_resource_instance.powervs_workspace.guid
}

locals {
  catalog_images_to_import = flatten([for stock_image in data.ibm_pi_catalog_images.catalog_images_ds.images : [for image_name in var.powervs_image_names : stock_image if stock_image.name == image_name]])
}

resource "ibm_pi_image" "import_images" {
  count                = length(var.powervs_image_names)
  pi_cloud_instance_id = ibm_resource_instance.powervs_workspace.guid
  pi_image_id          = local.catalog_images_to_import[count.index].image_id
  pi_image_name        = var.powervs_image_names[count.index]
}