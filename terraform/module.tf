module "nixos_image" {
    source = "github.com/tweag/terraform-nixos//aws_image_nixos"
    release = "latest"
}
