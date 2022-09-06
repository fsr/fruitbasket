{ config, pkgs, lib, ... }:
{
  sops.secrets = {
    "mediawiki/postgres".owner = config.users.users.mediawiki.name;
    "mediawiki/initial_admin".owner = config.users.users.mediawiki.name;
    "mediawiki/ldapprovider".owner = config.users.users.mediawiki.name;
  };

  services = {
    mediawiki = {
      enable = true;
      name = "FSR Wiki";
      passwordFile = config.sops.secrets."mediawiki/initial_admin".path;
      database = {
        type = "postgres";
        socket = "/var/run/postgresql";
        user = "mediawiki";
        name = "mediawiki";
      };

      virtualHost = {
        hostName = "wiki.quitte.tassilo-tanneberger.de";
        adminAddr = "root@ifsr.de";
        forceSSL = true;
        enableACME = true;
      };

      extraConfig = ''
        $wgArticlePath = '/$1';

        $wgShowExceptionDetails = true;
        $wgDBserver = "${config.services.mediawiki.database.socket}";
        $wgDBmwschema       = "mediawiki";

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
