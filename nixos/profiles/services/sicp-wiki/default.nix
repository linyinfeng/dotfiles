{ config, pkgs, ... }:
{
  services.mediawiki = {
    enable = true;
    name = "NJU SICP Wiki";
    url = "https://sicp-wiki.li7g.com";
    webserver = "nginx";
    database.type = "postgres";
    nginx = {
      hostName = "sicp-wiki.*";
    };
    passwordFile = config.sops.secrets."sicp_wiki_admin_password".path;
    extensions = {
      AuthManagerOAuth = pkgs.stdenv.mkDerivation {
        inherit (pkgs.nur.repos.linyinfeng.sources.mediawiki-auth-manager-oauth) pname version src;
        nativeBuildInputs = [
          pkgs.unzip
        ];
        installPhase = ''
          cp -r "." "$out"
        '';
      };
    };
    extraConfig = ''
      # Disable anonymous editing
      $wgGroupPermissions['*']['edit'] = false;

      # OAuth authentication
      $wgAuthManagerOAuthConfig = [
        'GitLab' => [
          'clientId'                => '270a8f1196894f2487a486648899844965face3a4d90de033763dc3da72e941d',
          'clientSecret'            => file_get_contents("${
            config.sops.secrets."mediawiki/oauth/gitlab/client-secret".path
          }"),
          'urlAuthorize'            => 'https://git.nju.edu.cn/oauth/authorize',
          'urlAccessToken'          => 'https://git.nju.edu.cn/oauth/token',
          'urlResourceOwnerDetails' => 'https://git.nju.edu.cn/api/v4/user',
          'scopes'                  => [ 'profile' ]
        ]
      ];

      # SVG upload
      $wgFileExtensions[] = 'svg';
      $wgSVGConverterPath = "${pkgs.imagemagick}/bin";

      # Pretty URLs
      $wgUsePathInfo = true;

      # Debug
      $wgDebugLogFile = "/var/log/mediawiki/debug.log";
      $wgShowExceptionDetails = true;
    '';
  };
  services.phpfpm.pools.mediawiki.phpOptions = ''
    upload_max_filesize = 2M
    post_max_size = 2M
  '';
  services.nginx.virtualHosts."sicp-wiki.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
  };
  systemd.tmpfiles.settings."90-mediawiki" = {
    "/var/log/mediawiki" = {
      "d" = {
        user = "mediawiki";
        group = "nginx";
        mode = "770";
      };
    };
  };
  sops.secrets."sicp_wiki_admin_password" = {
    terraformOutput.enable = true;
    owner = "mediawiki";
  };
  sops.secrets."mediawiki/oauth/gitlab/client-secret" = {
    sopsFile = config.sops-file.host;
    owner = "nginx";
    group = "nginx";
    mode = "440";
  };
}
