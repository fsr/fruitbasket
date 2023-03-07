{ config, pkgs, ... }:
let
  SOGo-hostname = "mail.${config.fsr.domain}";
  domain = config.fsr.domain;
in
{
  sops.secrets.sogo_ldap_search = {
    key = "portunus_search";
    # owner = config.systemd.services   keine Ahnung was hier hin soll


  };
  services = {
    sogo = {
      enable = true;
      language = "German";
      extraConfig = ''
        WOWorkersCount = 10;
        SOGoUserSources = ({
          type = ldap;
          CNFieldName = cn;
          UIDFieldName = uid;
          baseDN = "ou = users, dc=ifsr, dc=de";
          bindDN = "uid=search, ou=users, dc=ifsr, dc=de";
          bindPassword = ${config.sops.secrets.SOGo_ldap_search.path}; 
          hostname = "ldap://localhost";
          canAuthenticate = YES;
          id = directory;
      
        });
        SOGoProfileURL = "postgresql://sogo:sogo@localhost:5432/sogo/sogo_user_profile";    
				SOGoFolderInfoURL = "postgreql://sogo:sogo@localhost:5432/sogo/sogo_folder_info";
				OCSSessionsFolderURL = "postgresql://sogo:sogo@localhost:5432/sogo/sogo_sessions_folder";
				
      ''; # Hier ist bindPassword noch nicht vollständig
    };
    postgresql = {
      ensureUsers = [{
        name = "SOGo";
      }];
      ensureDatabases = [ "SOGo" ];
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts."${SOGo-hostname}" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:443";
            proxyWebsockets = true;
          };
        };


      };

    };
  }
}
