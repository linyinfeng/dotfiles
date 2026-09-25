{ ... }:
{
  devshells.default = {
    env = [
      {
        name = "DOTFILES_DIR";
        eval = "\${DOTFILES_DIR:-$(realpath \"$PRJ_ROOT\")}";
      }
      {
        name = "SECRETS_DIR";
        eval = "\${SECRETS_DIR:-$(realpath \"$PRJ_ROOT/../infrastructure-secrets\")}";
      }
      {
        name = "SECRETS_EXTRACT_DIR";
        eval = "\${SECRETS_EXTRACT_DIR:-$(realpath \"$DOTFILES_DIR/secrets\")}";
      }
      {
        name = "TERRAFORM_DIR";
        eval = "\${TERRAFORM_DIR:-$(realpath \"$DOTFILES_DIR/terraform\")}";
      }

      {
        name = "DATA_EXTRACT_DIR";
        eval = "\${DATA_EXTRACT_DIR:-$(realpath \"$DOTFILES_DIR/lib/data\")}";
      }
    ];
  };
}
