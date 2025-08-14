{ config, pkgs, ... }:
let
  domain = "kanboard.${config.networking.domain}";
  domain_short = "kb.${config.networking.domain}";

  cfg = config.services.kanboard;
in
{
  sops.secrets."kanboard_env" = { };

  services.kanboard = {
    enable = true;
    nginx = null;

    # to prevent downgrade from docker image version
    package = pkgs.kanboard.overrideAttrs rec {
      version = "1.2.46";
      src = pkgs.fetchFromGitHub {
        owner = "kanboard";
        repo = "kanboard";
        tag = "v${version}";
        hash = "sha256-IYnlBNa4f+ZpOttQHlIZi8wsZYJuB/kWWLwhQK8vdQY=";
      };
    };

    phpfpm.settings = {
      clear_env = false;
    };

    settings = {
      ENABLE_URL_REWRITE = true;
      PLUGINS_DIR = "${cfg.dataDir}/plugins";
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
    };
  };
}
