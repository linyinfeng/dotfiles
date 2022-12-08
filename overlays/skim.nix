# load skim_key_bindings by home-manager
final: prev: {
  skim = prev.skim.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm $out/share/fish/vendor_conf.d/load-sk-key-bindings.fish
    '';
  });
}
