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

        auth_url = "https://sso.ifsr.de/realms/internal/protocol/openid-connect/auth";
        token_url = "https://sso.ifsr.de/realms/internal/protocol/openid-connect/token";
        api_url = "https://sso.ifsr.de/realms/internal/protocol/openid-connect/userinfo";
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
      postfix = {
        enable = true;
        port = 9003;
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
        job_name = "postfix";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.postfix.port}" ];
        }];
        # scrape_interval = "60s";
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
