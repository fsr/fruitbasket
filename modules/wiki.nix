{ config, pkgs, lib, ... }:
let
  domain = "wiki.${config.fsr.domain}";
  listenPort = 8080;
in
{
  sops.secrets = {
    "mediawiki/postgres".owner = config.users.users.mediawiki.name;
    "mediawiki/initial_admin".owner = config.users.users.mediawiki.name;
    "mediawiki/ldapprovider".owner = config.users.users.mediawiki.name;
  };

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
        $wgEmergencyContact = "root@ifsr.de";
        $wgPasswordSender   = "root@ifsr.de";
        $wgLanguageCode = "de";

        $wgGroupPermissions['*']['edit'] = false;
        $wgGroupPermissions['user']['edit'] = true;
        $wgGroupPermissions['sysop']['interwiki'] = true;
        $wgGroupPermissions['sysop']['userrights'] = true;
        $wgGroupPermissions['sysop']['deletelogentry'] = true;
        $wgGroupPermissions['sysop']['deleterevision'] = true;

        $wgEnableAPI = true;
        $wgAllowUserCss = true;
        $wgUseAjax = true;
        $wgEnableMWSuggest = true;

        //TODO what about $wgUpgradeKey ?

        $wgScribuntoDefaultEngine = 'luastandalone';

        # LDAP
        $LDAPProviderDomainConfigs = "${config.sops.secrets."mediawiki/ldapprovider".path}";
        $wgPluggableAuth_EnableLocalLogin = true;
      '';

      extensions = {
        CiteThisPage = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220627203556/https://extdist.wmflabs.org/dist/extensions/CiteThisPage-REL1_38-bb4881c.tar.gz";
          sha256 = "sha256-sTZMCLlOkQBEmLiFz2BQJpWRxSDbpS40EZQ+f/jFjxI=";
        };
        ConfirmEdit = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220627203619/https://extdist.wmflabs.org/dist/extensions/ConfirmEdit-REL1_38-50f4dfd.tar.gz";
          sha256 = "sha256-babZDzcQDE446TBuGW/olbt2xRbPjk+5o3o9DUFlCxk=";
        };
        Lockdown = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220627203048/https://extdist.wmflabs.org/dist/extensions/Lockdown-REL1_38-1915db4.tar.gz";
          sha256 = "sha256-YCYsjh/3g2P8oT6IomP3UWjOoggH7jYjiiix7poOYnA=";
        };
        intersection = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220627203336/https://extdist.wmflabs.org/dist/extensions/intersection-REL1_38-8525097.tar.gz";
          sha256 = "sha256-shgA0XLG6pgikqldOfda40hV9zC1eBp+NalGhevFq2Q=";
        };
        Interwiki = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220617074130/https://extdist.wmflabs.org/dist/extensions/Interwiki-REL1_38-223bbf8.tar.gz";
          sha256 = "sha256-A4tQuISJNzzXPXJXv9N1jMat1VuZ7khYzk2jxoUqzIk=";
        };
        # requires PluggableAuth
        LDAPAuthentication2 = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220807184305/https://extdist.wmflabs.org/dist/extensions/LDAPAuthentication2-master-6bc5848.tar.gz";
          sha256 = "sha256-32xUhahDObS1S9vYJn61HsbpqyFuL0UAsV5+rmH3iWo=";
        };
        LDAPProvider = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220806214957/https://extdist.wmflabs.org/dist/extensions/LDAPProvider-master-80f8cc8.tar.gz";
          sha256 = "sha256-Y59otw6onknVsjRhyH7L7I0MwnBkvQtuzwpj7c0GZzc=";
        };
        ParserFunctions = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220627203519/https://extdist.wmflabs.org/dist/extensions/ParserFunctions-REL1_38-bc6a7c6.tar.gz";
          sha256 = "sha256-iDv4VSSFnTKEhvlVQcHHVp2hSWwDbv6jNCq1kOGuswo=";
        };
        PluggableAuth = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220807185047/https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_38-126bad8.tar.gz";
          sha256 = "sha256-cdJdhj7+qisVVePuyKDu6idoUy0+gYo3zMN0y6weH84=";
        };
        #Scribunto = pkgs.fetchzip {
        #  url = "https://web.archive.org/web/20220627202748/https://extdist.wmflabs.org/dist/extensions/Scribunto-REL1_38-9b9271a.tar.gz";
        #  sha256 = "sha256-4sy2ZCnDFzx43WzfS4Enh+I0o0+sFl1RnNV4xGiyU0k=";
        #};
        SyntaxHightlight = pkgs.fetchzip {
          url = "https://web.archive.org/web/20220627203440/https://extdist.wmflabs.org/dist/extensions/SyntaxHighlight_GeSHi-REL1_38-79031cd.tar.gz";
          sha256 = "sha256-r1NgrhSratleQ356imxmF7KmAANvWvKpAgnLkm8IdKY=";
        };
      };
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts.${domain} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString listenPort}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
