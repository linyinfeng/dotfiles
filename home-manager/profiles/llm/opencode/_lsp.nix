{
  pkgs,
  lib,
  ...
}:
{
  programs.opencode.settings.lsp = {
    nixd = {
      command = [ (lib.getExe pkgs.nixd) ];
      extensions = [ ".nix" ];
      initialization = {
        nixpkgs.expr = "import <nixpkgs> { }";
        formatting = {
          command = [ (lib.getExe pkgs.nixfmt) ];
        };
        options = {
          nixos.expr = ''(builtins.getFlake "self").lib.nixd.nixosOptions'';
          home-manager.expr = ''(builtins.getFlake "self").lib.nixd.homeManagerOptions'';
          flake-parts.expr = ''(builtins.getFlake "self").debug.options'';
          flake-parts-per-system.expr = ''(builtins.getFlake "self").currentSystem.options'';
        };
      };
    };
    rust = {
      command = [ (lib.getExe pkgs.rust-analyzer) ];
      extensions = [ ".rs" ];
    };
    taplo = {
      command = [
        (lib.getExe pkgs.taplo)
        "lsp"
        "stdio"
      ];
      extensions = [ ".toml" ];
    };
    jsonls = {
      command = [
        (lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server")
        "--stdio"
      ];
      extensions = [
        ".json"
        ".jsonc"
      ];
    };
    yamlls = {
      command = [
        (lib.getExe pkgs.yaml-language-server)
        "--stdio"
      ];
      extensions = [
        ".yaml"
        ".yml"
      ];
    };

    html = {
      command = [
        (lib.getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server")
        "--stdio"
      ];
      extensions = [
        ".html"
        ".htm"
      ];
    };
    sqls = {
      command = [ (lib.getExe pkgs.sqls) ];
      extensions = [ ".sql" ];
    };
    typos-lsp = {
      command = [ (lib.getExe pkgs.typos-lsp) ];
      extensions = [
        ".md"
        ".markdown"
        ".mdx"
        ".txt"
      ];
      initialization = {
        diagnosticSeverity = "Warning";
      };
    };

    fish-lsp = {
      command = [ (lib.getExe pkgs.fish-lsp) ];
      extensions = [ ".fish" ];
    };

    typescript = {
      command = [
        (lib.getExe pkgs.typescript-language-server)
        "--stdio"
      ];
      extensions = [
        ".ts"
        ".tsx"
        ".js"
        ".jsx"
        ".mjs"
        ".cjs"
        ".mts"
        ".cts"
      ];
    };

    gopls = {
      command = [ (lib.getExe pkgs.gopls) ];
      extensions = [
        ".go"
        ".mod"
        ".sum"
      ];
    };
    bashls = {
      command = [
        (lib.getExe pkgs.bash-language-server)
        "start"
      ];
      extensions = [
        ".sh"
        ".bash"
      ];
    };
    ruff = {
      command = [
        (lib.getExe pkgs.ruff)
        "server"
      ];
      extensions = [
        ".py"
        ".pyi"
        ".pyw"
      ];
    };
  };
}
