{
  self,
  lib,
}:
let
  # `attrsToRemove` ∪ `shorthandAttrsToRemove` from nixpkgs' `unifyModuleSyntax`, keep in
  # sync: `wrap` emits the explicit form, so it does the shorthand -> explicit split itself
  # (letting `_class` fall into `config` is what broke flake-parts' modules). `require`
  # only stays here so that it is not mistaken for configuration: passing it on makes the
  # module system reject it, since the explicit form has no `require`.
  moduleKeys = [
    "options"
    "imports"
    "disabledModules"
    "require"
    "meta"
    "freeformType"
    "_class"
    "_file"
    "key"
  ];

  leaves =
    src:
    lib.mapAttrsToList (rel: file: {
      path = lib.filter (part: part != "") (lib.splitString "/" rel);
      inherit file;
    }) (self.flattenTree { } (self.rakeLeaves src));

  wrap =
    {
      gatePath,
      declare ? { },
      file,
    }:
    let
      inner = if builtins.isPath file || builtins.isString file then import file else file;
    in
    # Mirror the wrapped module's formals: the module system only passes declared arguments.
    lib.setFunctionArgs (
      args:
      let
        m = lib.toFunction inner args;
        m' = if builtins.isList m then { imports = m; } else m;
        attrs = lib.filterAttrs (name: _: builtins.elem name moduleKeys) m';
      in
      attrs
      // {
        imports = lib.map (
          i:
          wrap {
            inherit gatePath;
            file = i;
          }
        ) (attrs.imports or [ ]);
        options = (attrs.options or { }) // declare;
        # Explicit module: `config`. Shorthand: everything else.
        config = lib.mkIf (lib.attrByPath gatePath false args.config) (
          m'.config or (lib.removeAttrs m' (builtins.attrNames attrs))
        );
      }
    ) (if lib.isFunction inner then lib.functionArgs inner else { });
in
{
  mkWorld =
    {
      src,
      tree,
      enable,
    }:
    lib.map (
      leaf:
      let
        worldPath = [ tree ] ++ leaf.path;
        gatePath = [ "world" ] ++ worldPath ++ [ "enable" ];
      in
      wrap {
        inherit gatePath;
        inherit (leaf) file;
        declare = lib.setAttrByPath gatePath (
          lib.mkEnableOption (lib.concatStringsSep "." worldPath)
          // {
            default = enable;
          }
        );
      }
    ) (leaves src);

  mkWorldLeaves = leaves;
}
