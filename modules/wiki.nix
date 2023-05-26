{ config, pkgs, lib, ... }:
{
  sops.secrets = {
    "mediawiki/postgres".owner = config.users.users.mediawiki.name;
    "mediawiki/initial_admin".owner = config.users.users.mediawiki.name;
    "mediawiki/ldapprovider".owner = config.users.users.mediawiki.name;
  };

  #  users.users.mediawiki.extraGroups = [ "postgres" ];
  nixpkgs.overlays = [
    (final: prev: {
      final.config.systemd.services.mediawiki-init.script = ''
        	
        	'';
    })
  ];
  services = {
    mediawiki = {
      enable = true;
      name = "FSR Wiki";
      passwordFile = config.sops.secrets."mediawiki/initial_admin".path;
      database = {
        createLocally = false;
        type = "postgres";
        user = "mediawiki";
        name = "mediawiki";
        host = "localhost";
        port = 5432;
        passwordFile = config.sops.secrets."mediawiki/postgres".path;
        createLocally = false;
      };

      #      virtualHost = {
      #        hostName = "wiki.quitte.tassilo-tanneberger.de";
      #        adminAddr = "root@ifsr.de";
      #        forceSSL = true;
      #        enableACME = true;
      #      };

      httpd.virtualHost = {
        hostName = "wiki.${config.fsr.domain}";
        adminAddr = "root@ifsr.de";
        #forceSSL = true;
        #enableACME = true;
      };

      httpd.virtualHost.listen = [
        {
          ip = "127.0.0.1";
          port = 8080;
          ssl = false;
        }
      ];

      extraConfig = ''
        	$wgDBport = "5432";
        	$wgDBmwschema = "mediawiki";

        	$wgDBserver = "localhost";
        	$wgDBname = "mediawiki";


                /////// $wgArticlePath = '/$1';

                // $wgLogo =  "https://www.c3d2.de/images/ck.png";
                $wgEmergencyContact = "root@ifsr.de";
                $wgPasswordSender   = "root@ifsr.de";
                $wgLanguageCode = "de";

                $wgGroupPermissions['*']['edit'] = false;
                $wgGroupPermissions['user']['edit'] = true;
                $wgGroupPermissions['sysop']['interwiki'] = true;
                $wgGroupPermissions['sysop']['userrights'] = true;

                define("NS_INTERN", 100);
                define("NS_INTERN_TALK", 101);

                $wgExtraNamespaces[NS_INTERN] = "Intern";
                $wgExtraNamespaces[NS_INTERN_TALK] = "Intern_Diskussion";

                $wgGroupPermissions['intern']['move']             = true;
                $wgGroupPermissions['intern']['move-subpages']    = true;
                $wgGroupPermissions['intern']['move-rootuserpages'] = true; // can move root userpages
                $wgGroupPermissions['intern']['read']             = true;
                $wgGroupPermissions['intern']['edit']             = true;
                $wgGroupPermissions['intern']['createpage']       = true;
                $wgGroupPermissions['intern']['createtalk']       = true;
                $wgGroupPermissions['intern']['writeapi']         = true;
                $wgGroupPermissions['intern']['upload']           = true;
                $wgGroupPermissions['intern']['reupload']         = true;
                $wgGroupPermissions['intern']['reupload-shared']  = true;
                $wgGroupPermissions['intern']['minoredit']        = true;
                $wgGroupPermissions['intern']['purge']            = true; // can use ?action=purge without clicking "ok"
                $wgGroupPermissions['intern']['sendemail']        = true;

                $wgNamespacePermissionLockdown[NS_INTERN]['*'] = array('intern');
                $wgNamespacePermissionLockdown[NS_INTERN_TALK]['*'] = array('intern');

                $wgGroupPermissions['sysop']['deletelogentry'] = true;
                $wgGroupPermissions['sysop']['deleterevision'] = true;

                wfLoadExtension('ConfirmEdit/QuestyCaptcha');
                $wgCaptchaClass = 'QuestyCaptcha';
                $wgCaptchaQuestions[] = array( 'question' => 'How is C3D2 logo in ascii?', 'answer' => '<<</>>' );

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
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "mediawiki";
          ensurePermissions = {
            "DATABASE \"mediawiki\"" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = [
        "mediawiki"
      ];
    };
    nginx = {
      recommendedProxySettings = true;
      virtualHosts = {
        "wiki.${config.fsr.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            proxyWebsockets = true;
          };
        };
      };
    };

  };
  systemd.services.mediawiki-pgsetup = {
    description = "Prepare Mediawiki postgres database";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" "postgresql.service" ];
    serviceConfig.Type = "oneshot";

    path = [ pkgs.sudo config.services.postgresql.package ];
    script = ''
      sudo -u ${config.services.postgresql.superUser} psql -c "ALTER ROLE mediawiki WITH PASSWORD '$(cat ${config.sops.secrets."mediawiki/postgres".path})'"
    '';
  };
}
