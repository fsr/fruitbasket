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
        wfLoadSkin( 'MinervaNeue' );
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
        $wgDefaultMobileSkin = 'minerva';

        //TODO what about $wgUpgradeKey ?

        # Auth
        # https://www.mediawiki.org/wiki/Extension:PluggableAuth
        # https://www.mediawiki.org/wiki/Extension:OpenID_Connect
        $wgOpenIDConnect_MigrateUsersByEmail = true;
        //$wgOpenIDConnect_MigrateUsersByUserName = true;
        $wgPluggableAuth_EnableLocalLogin = false;
        $wgPluggableAuth_EnableAutoLogin = true;
        $wgPluggableAuth_Config["iFSR Login"] = [
          "plugin" => "OpenIDConnect",
          "data" => [
            "providerURL" => "https://idm.ifsr.de/application/o/wiki/",
            "clientID" => "wiki",
            "clientsecret" => file_get_contents('${config.sops.secrets."mediawiki/oidc_secret".path}'),
          ],
        ];
      '';
      extensions = {
        # some extensions are included and can enabled by passing null
        VisualEditor = null;
        # the dir in the mediawiki-1.42.3.tar.gz inside of the extension folder is called "SyntaxHighlight_GeSHi" not "SyntaxHighlight"
        SyntaxHighlight_GeSHi = null;
        MobileFrontend = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/MobileFrontend-REL1_44-93b8f3d.tar.gz";
          hash = "sha256-Dhu21+s2u9b18RIdm/z63vX22+S2aLO81mQOWI457bw=";
        };
        PluggableAuth = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_44-9cf6960.tar.gz";
          hash = "sha256-jx3Pw4jZ86WO0jwNyIBguNLCpwzxKEDJDAzm5I7YtNM=";
        };
        OpenIDConnect = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_44-438d993.tar.gz";
          hash = "sha256-TpFEToogaN76Ll6jkbU0CMfNQT/+Zl7xny8woPr7Oh8=";
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
