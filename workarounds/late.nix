# Workarounds layered on top of ../flake/nixpkgs.nix, only for packages whose
# upstream fix has not reached nixos-unstable yet.
{
  inputs,
  lib,
  channelsOf,
}:
[
  (
    final: prev:
    let
      piperPython = prev.python3.override {
        self = piperPython;
        packageOverrides = _pyFinal: pyPrev: {
          # its test_frontend asserts the TypeError wording Cython switched away
          # from in 3.2; nixpkgs master carries the same fix.
          pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ../patches/pyopenjtalk-plus-cython-error-message.patch
            ];
          });
        };
      };
      # configure only installs the python bindings when `python3` is on PATH;
      # nixpkgs master passes it through nativeBuildInputs instead, so drop this
      # once nixos-unstable catches up.
      fixSpeechd =
        drv:
        drv.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.python3 ];
        });
    in
    {
      shim-unsigned = (channelsOf final).stable.shim-unsigned; # TODO fix
      nginx =
        if lib.versionAtLeast prev.nginx.version "1.30.1" then
          prev.nginx
        else
          # TODO wait for https://nixpkgs-tracker.ocfox.me/?pr=519893
          (channelsOf final).latest.nginx;
      # calibre only runs piper's inference CLI; the default `withTrain` pulls
      # the whole training stack (librosa -> scikit-learn, torch, lightning),
      # and scikit-learn's checks fail on the emulated aarch64 builder.
      calibre = prev.calibre.override {
        # calibre imports speechd's python bindings; patch only its own instance,
        # overriding the package set itself would also rebuild chromium/electron
        speechd-minimal = fixSpeechd prev.speechd-minimal;
        piper-tts = prev.piper-tts.override {
          python3Packages = piperPython.pkgs;
          withTrain = false;
        };
      };
      # the aarch64 node module links against tpm2-tss, which upstream leaves
      # out of the inputs its ELF fixup resolves against
      chatgpt-unwrapped =
        (prev.callPackage "${inputs.llm-agents}/packages/chatgpt/unwrapped.nix" {
          flake = inputs.llm-agents;
          formatelf = prev.llm-agents.formatelf;
        }).overrideAttrs
          (old: {
            buildInputs =
              (old.buildInputs or [ ]) ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [ prev.tpm2-tss ];
          });
      llm-agents = prev.llm-agents // {
        chatgpt = prev.llm-agents.chatgpt.override { inherit (final) chatgpt-unwrapped; };
      };
      vscode = final.symlinkJoin {
        inherit (prev.vscode) pname version meta;
        paths = [ prev.vscode ];
        buildInputs = [ final.makeWrapper ];
        # TODO remove --password-store=gnome-libsecret
        # wait for https://github.com/microsoft/vscode/issues/187338
        postBuild = ''
          wrapProgram "$out/bin/code" \
            --add-flags --password-store=gnome-libsecret
        '';
      };
    }
  )
]
