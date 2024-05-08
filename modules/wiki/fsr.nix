{ config, pkgs, ... }:
let
  domain = "wiki.${config.networking.domain}";
  listenPort = 8080;
in
{
  sops.secrets = {
    "mediawiki/initial_admin".owner = config.users.users.mediawiki.name;
    "mediawiki/oidc_secret".owner = config.users.users.mediawiki.name;
  };

  systemd.services.mediawiki-init.after = [ "postgresql.service" ];
  services = {
    mediawiki = {
      enable = true;
      passwordFile = config.sops.secrets."mediawiki/initial_admin".path;
      database.type = "postgres";
      url = "https://${domain}";

      httpd.virtualHost = {
        adminAddr = "root@ifsr.de";
        listen = [{
          ip = "127.0.0.1";
          port = listenPort;
          ssl = false;
        }];
        # Short url support (e.g. https://wiki.ifsr.de/Page instead of .../index.php?title=Page)
        # Recommended config taken from https://www.mediawiki.org/wiki/Manual:Short_URL/Apache
        # See paragraph "If you are using a root url ..."
        extraConfig = ''
          RewriteEngine On
          RewriteCond %{REQUEST_URI} !^/rest\.php
          RewriteCond %{REQUEST_URI} !^/images
          RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} !-f
          RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} !-d
          RewriteRule ^(.*)$ %{DOCUMENT_ROOT}/index.php [L]
        '';
      };

      extraConfig = ''
        $wgSitename = "FSR Wiki";
        $wgArticlePath = '/$1';

        $wgLogo =  "/images/3/3b/LogoiFSR.png";
        $wgLanguageCode = "de";

        $wgGroupPermissions['*']['read'] = false;
        $wgGroupPermissions['*']['edit'] = false;
        $wgGroupPermissions['*']['createaccount'] = false;
        $wgGroupPermissions['*']['autocreateaccount'] = true;
        $wgGroupPermissions['sysop']['userrights'] = true;
        $wgGroupPermissions['sysop']['deletelogentry'] = true;
        $wgGroupPermissions['sysop']['deleterevision'] = true;

        $wgEnableAPI = true;
        $wgAllowUserCss = true;
        $wgUseAjax = true;
        $wgEnableMWSuggest = true;
        $wgDefaultSkin = 'timeless';

        //TODO what about $wgUpgradeKey ?

        # Auth
        # https://www.mediawiki.org/wiki/Extension:PluggableAuth
        # https://www.mediawiki.org/wiki/Extension:OpenID_Connect
        $wgOpenIDConnect_MigrateUsersByEmail = true;
        $wgPluggableAuth_EnableLocalLogin = true;
        $wgPluggableAuth_Config["iFSR Login"] = [
          "plugin" => "OpenIDConnect",
          "data" => [
            "providerURL" => "https://sso.ifsr.de/realms/internal",
            "clientID" => "wiki",
            "clientsecret" => file_get_contents('${config.sops.secrets."mediawiki/oidc_secret".path}'),
          ],
        ];
      '';

      extensions = {
        PluggableAuth = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_40-3689731.tar.gz";
          hash = "sha256-BMA0qV+x+iQt/P9tbl9csEUni9jiQcBtZeuwdjx2QPk=";
        };
        OpenIDConnect = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_40-b354cdb.tar.gz";
          hash = "sha256-gLHaveEzfmpqU9fWATZsUU377FJj2yq//raHZUR/VWk=";
        };
        VisualEditor = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/VisualEditor-REL1_40-8970b62.tar.gz";
          hash = "sha256-G+qvKVuF6OCnwS5q2cKfij1/aH1I6lOw84K6fED980s=";
        };
        SyntaxHighlight = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/SyntaxHighlight_GeSHi-REL1_40-1170e8f.tar.gz";
          hash = "sha256-75+wwTvHhwPBP1jVLK2fQWBi7vznOvPVgNpY3kzWJtg=";
        };
      };
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts.${domain} = {
        locations."/robots.txt" = {
          extraConfig = ''
            add_header  Content-Type  text/plain;
            return 200 "User-agent: *\nDisallow: /\n";
          '';
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString listenPort}";
          proxyWebsockets = true;
        };
        locations."~ ^/ese(/?[^\\n|\\r]*)$".return = "301 https://wiki.ese.ifsr.de$1";
        locations."~ ^/fsr(/?[^\\n|\\r]*)$".return = "301 https://wiki.ifsr.de$1";
        locations."~ ^/vernetzung(/?[^\\n|\\r]*)$".return = "301 https://vernetzung.ifsr.de$1";
      };
    };
  };
}
