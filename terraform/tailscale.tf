provider "tailscale" {
  api_key = data.sops_file.terraform.data["tailscale.api-key"]
  tailnet = data.sops_file.terraform.data["tailscale.tailnet"]
}

resource "tailscale_tailnet_key" "tailnet_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
}

output "tailscale_tailnet_key" {
  value = tailscale_tailnet_key.tailnet_key.key
  sensitive = true
}

resource "tailscale_acl" "main" {
  acl = jsonencode({
    acls : [
      {
        // allow all users access to all ports.
        action = "accept",
        ports  = ["*:*"],
        users  = ["*"],
      }
    ],
    # derpMap : {
    #   regions : {
    #     "900" : {
    #       regionID : 900,
    #       regionCode : "sha",
    #       regionName : "Shanghai",
    #       nodes : [
    #         {
    #           name : "900a",
    #           regionID : 900,
    #           hostName : "shanghai.derp.li7g.com",
    #           ipv4 : var.tencent_ip,
    #           derpPort : 8443,
    #         },
    #       ],
    #     },
    #   },
    # },
  })
}
