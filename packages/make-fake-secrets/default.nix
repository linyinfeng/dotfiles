{
  writeShellApplication,
  yq-go,
  sops,
}:
writeShellApplication {
  name = "make-fake-secrets";
  runtimeInputs = [
    yq-go
    sops
  ];
  text = ''
    input="$1"
    output="$2"
    output_dir="$(dirname "$output")"
    tmp_dir="$(mktemp --directory -t make-fake-secrets.XXXXXX)"

    mkdir -p "$output_dir"
    yq eval 'del(.sops) | (.. | select(tag == "!!str")) |= sub("^ENC\[.*\]$", "")' \
      "$input" >"$tmp_dir/raw.yaml"
    sops encrypt --age '${builtins.fromJSON (builtins.readFile ./test-key-pub.json)}' \
      --input-type yaml "$tmp_dir/raw.yaml" \
      --output-type yaml --output "$output"
  '';
}
