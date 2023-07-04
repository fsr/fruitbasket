{ config, pkgs, lib, ... }:
let
  sogo-hostname = "mail.${config.fsr.domain}";
  domain = config.fsr.domain;
  pg-port = toString config.services.postgresql.port;
in
{
  sops.secrets.ldap_search = {
    owner = config.systemd.services.sogo.serviceConfig.User;
  };
  sops.secrets.postgres_sogo = {
    owner = config.systemd.services.sogo.serviceConfig.User;
  };

  services = {
    memcached.enable = true;
    sogo = {
      enable = true;
      language = "German";
      extraConfig = ''
        WOWorkersCount = 10;
        SOGoUserSources = ({
          type = ldap;
          CNFieldName = cn;
          UIDFieldName = uid;
          IDFieldName = uid;

          baseDN = "ou=users, dc=ifsr, dc=de";
          bindDN = "uid=search, ou=users, dc=ifsr, dc=de";
          bindPassword = LDAP_SEARCH;
          hostname = "ldap://localhost";
          canAuthenticate = YES;
          id = directory;
      
        });
        SOGoProfileURL = "postgresql://sogo:POSTGRES_PASSWORD@localhost:${pg-port}/sogo/sogo_user_profile";    
        OCSSessionsFolderURL = "postgresql://sogo:POSTGRES_PASSWORD@localhost:${pg-port}/sogo/sogo_sessions_folder";
        OCSFolderInfoURL = "postgresql://sogo:POSTGRES_PASSWORD@localhost:${pg-port}/sogo/sogo_folder_info";
        SOGoSieveServer = sieve://127.0.0.1:4190;
        SOGoSieveScriptsEnabled = YES;
        SOGoVacationEnabled = YES;
        SOGoForwardEnabled = YES;
      '';
      configReplaces = {
        "LDAP_SEARCH" = config.sops.secrets.ldap_search.path;
        "POSTGRES_PASSWORD" = config.sops.secrets.postgres_sogo.path;
      };
      vhostName = "${sogo-hostname}";
      timezone = "Europe/Berlin";
    };
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "sogo";
          ensurePermissions = {
            "DATABASE sogo" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = [ "sogo" ];
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts."${sogo-hostname}" = {
        extraConfig = ''
          proxy_busy_buffers_size   64k;
          proxy_buffers   8 64k;
          proxy_buffer_size   64k;
        '';
        forceSSL = true;
        enableACME = true;
        locations = {


          "^~/SOGo".extraConfig = lib.mkForce ''
            proxy_pass http://127.0.0.1:20000;
            proxy_redirect http://127.0.0.1:20000 default;

            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $host;
            proxy_set_header x-webobjects-server-protocol HTTP/1.0;
            proxy_set_header x-webobjects-remote-host 127.0.0.1;
            proxy_set_header x-webobjects-server-port $server_port;
            proxy_set_header x-webobjects-server-name $server_name;
            proxy_set_header x-webobjects-server-url $scheme://$host;
            proxy_connect_timeout 90;
            proxy_send_timeout 90;
            proxy_read_timeout 90;
            proxy_buffer_size 64k;
            proxy_buffers 8 64k;
            proxy_busy_buffers_size 64k;
            proxy_temp_file_write_size 64k;
            client_max_body_size 50m;
            client_body_buffer_size 128k;
            break;
          '';


        };
      };
    };
  };

  systemd.services.sogo.after = [ "sogo-pgsetup.service" ];

  # one of these prevents access to sendmail, don't know which one
  systemd.services.sogo.serviceConfig = {
    LockPersonality = lib.mkForce false;

    MemoryDenyWriteExecute = lib.mkForce false;
    NoNewPrivileges = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    PrivateUsers = lib.mkForce false;
    ProtectClock = lib.mkForce false;
    ProtectHostname = lib.mkForce false;
    ProtectKernelLogs = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    RestrictAddressFamilies = lib.mkForce [ ];
    RestrictRealtime = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
    SystemCallArchitectures = lib.mkForce "";
    SystemCallFilter = lib.mkForce [ ];
    ReadWriteDirectories = "/var/lib/postfix/queue/maildrop";

  };

  systemd.services.sogo-pgsetup = {
    description = "Prepare Sogo postgres database";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" "postgresql.service" ];
    serviceConfig.Type = "oneshot";

    path = [ pkgs.sudo config.services.postgresql.package ];
    script = ''
      sudo -u ${config.services.postgresql.superUser} psql -c "ALTER ROLE sogo WITH PASSWORD '$(cat ${config.sops.secrets.postgres_sogo.path})'"
    '';
  };

}
