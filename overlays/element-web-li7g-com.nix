final: prev: {
  element-web-li7g-com = final.runCommandNoCC "element-web-with-config" { } ''
    cp -r ${final.element-web} $out
    chmod u+w $out
    rm $out/config.json
    cat ${final.element-web}/config.json |\
      ${final.jq}/bin/jq '."default_server_config"."m.homeserver" = { "base_url": "https://matrix.li7g.com", "server_name": "li7g.com" }' \
      > $out/config.json
  '';
}
