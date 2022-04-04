terraform {
  backend "remote" {
    organization = "li7g-com"
    workspaces {
      name = "dotfiles"
    }
  }
}
