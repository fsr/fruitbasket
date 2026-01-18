{ config, pkgs, ... }:
let
  domain = "kanboard.${config.networking.domain}";
  domain_short = "kb.${config.networking.domain}";

  cfg = config.services.kanboard;

  plugins = {
    Telegram = pkgs.fetchFromGitHub {
      owner = "manuvarkey";
      repo = "kanboard-plugin-telegram";
      rev = "05933dae827cbe84d36441bf6d301f1f9751fbbe";
      hash = "sha256-+xvYC3bikNxFFQN33X557zwq5cMDo1gUG9H99dJ9f5U=";
    };
    OAuth2 = pkgs.fetchFromGitHub {
      owner = "kanboard";
      repo = "plugin-oauth2";
      rev = "affb65ce40392290b0547f3ed5f41a62aa323518";
      postFetch = ''
        cd $out
        patch -p1 < ${./plugin-oauth2-admin-role.patch}
      '';
      hash = "sha256-S/mm7cJUHMyU8qgcu9jq9LUAKPZPhRgQFU8db9pugBw=";
    };
  };

  pluginsDir = pkgs.linkFarm "kanboard-plugins" plugins;
in
{
  sops.secrets."kanboard_env" = { };

  services.kanboard = {
    enable = true;
    nginx = null;
    phpfpm.settings = {
      clear_env = false;
    };

    settings = {
      ENABLE_URL_REWRITE = true;
      PLUGINS_DIR = toString pluginsDir;
    };
  };

  systemd.services.phpfpm-kanboard.serviceConfig = {
    EnvironmentFile = [
      config.sops.secrets."kanboard_env".path
    ];
  };

  services.nginx = {
    virtualHosts."${domain_short}" = {
      locations."/".return = "301 $scheme://${domain}$request_uri";
    };

    # virtualHost config copied from kanboard module,
    # because otherwise it breaks with our default options override
    virtualHosts.${domain} = {
      root = "${cfg.package}/share/kanboard";
      locations."/".extraConfig = ''
        rewrite ^ /index.php;
      '';
      locations."~ \\.php$".extraConfig = ''
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${config.services.phpfpm.pools.kanboard.socket};
        include ${config.services.nginx.package}/conf/fastcgi.conf;
        include ${config.services.nginx.package}/conf/fastcgi_params;
      '';
      locations."~ \\.(js|css|ttf|woff2?|png|jpe?g|svg)$".extraConfig = ''
        add_header Cache-Control "public, max-age=15778463";
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;
        access_log off;
      '';
      extraConfig = ''
        try_files $uri /index.php;
      '';

      # auto redirect login to sso
      locations."/login".return = "302 /oauth/callback";
    };
  };
}
