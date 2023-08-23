{ config, pkgs, lib, ... }:
let
  domain = "wiki.ifsr.de";
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
          RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} !-f
          RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} !-d
          RewriteRule ^(.*)$ %{DOCUMENT_ROOT}/index.php [L]
        '';
      };

      extraConfig = ''
        $wgSitename = "FSR Wiki";
        $wgArticlePath = '/$1';

        // $wgLogo =  "https://www.c3d2.de/images/ck.png";
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
          url = "https://web.archive.org/web/20230615112924/https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_39-068be5d.tar.gz";
          hash = "sha256-kmdSPMQNaO0qgEzb8j0+eLlsNQLmfJfo0Ls4yvYgOFI=";
        };
        OpenIDConnect = pkgs.fetchzip {
          url = "https://web.archive.org/web/20230615113527/https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_39-42e4d75.tar.gz";
          hash = "sha256-VN0G0Crjlx0DTLeDvaSFtMmYsfB7VzgYkSNDS+nkIyQ=";
        };
        VisualEditor = pkgs.fetchzip {
          url = "https://web.archive.org/web/20230723212424/https://extdist.wmflabs.org/dist/extensions/VisualEditor-REL1_39-b1204c9.tar.gz";
          hash = "sha256-g/ATW3xkecHynwbwLbmYgawNW+LCVTth0ZlhY7A3N5U=";
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
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString listenPort}";
          proxyWebsockets = true;
        };
        locations."~ ^/ese/([^\\n|\\r]*)$".return = "301 https://wiki.ese.ifsr.de/$1";
        locations."~ ^/fsr/([^\\n|\\r]*)$".return = "301 https://wiki.ifsr.de/$1";
      };
    };
  };
}
