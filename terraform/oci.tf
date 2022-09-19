locals {
    tenancy_ocid = data.sops_file.terraform.data["oci.tenancy_ocid"]
    root_compartment_id = local.tenancy_ocid
}

provider "oci" {
  tenancy_ocid = local.tenancy_ocid
  user_ocid    = data.sops_file.terraform.data["oci.user_ocid"]
  region       = data.sops_file.terraform.data["oci.region"]
  fingerprint  = data.sops_file.terraform.data["oci.fingerprint"]
  private_key  = data.sops_file.terraform.data["oci.private_key"]
}
resource "oci_identity_compartment" "terraform" {
    compartment_id = local.root_compartment_id
    name = "terraform"
    description = "Terraform-managed compartment"
}
