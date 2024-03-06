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
        $wgPluggableAuth_EnableLocalLogin = true;
        $wgPluggableAuth_Config["iFSR Login"] = [
          "plugin" => "OpenIDConnect",
          "data" => [
            "providerURL" => "${config.services.portunus.domain}/dex",
            "clientID" => "wiki",
            "clientsecret" => file_get_contents('${config.sops.secrets."mediawiki/oidc_secret".path}'),
          ],
        ];
      '';

      extensions = {
        PluggableAuth = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_40-2d86d50.tar.gz";
          hash = "sha256-NAdjc8pqAjSZrsN2IQ/rESyZYEnesBT0cGg8CrIlvFM=";
        };
        OpenIDConnect = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_40-e97e0b1.tar.gz";
          hash = "sha256-UrxaszLL3e4PZmTOnGkNliQ8fjGVD37Xj7BjhvhQDJU=";
        };
        VisualEditor = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/VisualEditor-REL1_40-c6aec49.tar.gz";
          hash = "sha256-p66C7ks0ocy5sL7LTkFQuDA3/2uSXdfldUXoOQ6afWM=";
        };
        SyntaxHighlight = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/SyntaxHighlight_GeSHi-REL1_40-ded412b.tar.gz";
          hash = "sha256-mlNrcZhGADqzdLNeck0ATv44W3cTTOykQouHJTaj5cA=";
        };
      };
    };

    portunus.dex.oidcClients = [{
      id = "wiki";
      callbackURL = "https://${domain}/Spezial:PluggableAuthLogin";
    }];

    nginx = {
      recommendedProxySettings = true;
      virtualHosts.${domain} = {
        enableACME = true;
        forceSSL = true;
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
