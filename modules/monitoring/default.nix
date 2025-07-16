{ config, ... }:
let
  domain = "monitoring.${config.networking.domain}";
in
{
  sops.secrets."grafana/oidc_secret" = {
    owner = "grafana";
  };
  # grafana configuration
  services.grafana = {
    enable = true;
    settings = {
      server = {
        inherit domain;
        http_addr = "127.0.0.1";
        http_port = 2342;
        root_url = "https://monitoring.ifsr.de";
      };
      database = {
        type = "postgres";
        user = "grafana";
        host = "/run/postgresql";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "iFSR";
        allow_sign_up = true;
        client_id = "grafana";
        client_secret = "$__file{${config.sops.secrets."grafana/oidc_secret".path}}";
        scopes = "openid email profile offline_access roles";

        email_attribute_path = "email";
        login_attribute_path = "username";
        name_attribute_path = "full_name";

        auth_url = "https://idm.ifsr.de/application/o/authorize/";
        token_url = "https://idm.ifsr.de/application/o/token/";
        api_url = "https://idm.ifsr.de/application/o/userinfo/";
        role_attribute_path = "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'";
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "grafana" ];
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
        scrape_interval = "15s";
      }
      {
        job_name = "rspamd";
        static_configs = [{
          targets = [ "rspamd.ifsr.de:11334" ];
        }];
        scrape_interval = "15s";
      }
      {
        job_name = "fabric";
        static_configs = [{
          targets = [ "127.0.0.1:25585" ];
        }];
        scrape_interval = "60s";
      }
    ];
  };

  # nginx reverse proxy
  services.nginx.virtualHosts.${domain} = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };
}
