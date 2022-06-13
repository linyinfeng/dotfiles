locals {
  rica_ip = data.sops_file.rica.data["network.address"]
}
