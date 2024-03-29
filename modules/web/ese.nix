{ config, pkgs, ... }:
let
  domain = "ese.${config.networking.domain}";
  cms-domain = "directus-ese.${config.networking.domain}";
in
{
  sops.secrets."directus_env" = { };
  environment.systemPackages = [ pkgs.nodejs_21 ];
  virtualisation.oci-containers = {
    backend = "docker";
    containers.directus-ese = {
      image = "directus/directus:latest";
      volumes = [
        "/srv/web/directus-ese/uploads:/directus/uploads"
        "/srv/web/directus-ese/database:/directus/database"
      ];
      ports = [ "127.0.0.1:8055:8055" ];
      extraOptions = [ "--network=host" ];
      environment = {
        "DB_CLIENT" = "pg";
        "DB_HOST" = "localhost";
        "DB_PORT" = "5432";
        "DB_DATABASE" = "directus_ese";
        "DB_USER" = "directus_ese";
      };
      environmentFiles = [
        config.sops.secrets."directus_env".path
      ];

    };
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "directus_ese";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "directus_ese" ];
  };

  services.nginx = {
    virtualHosts."${cms-domain}" = {
      locations."/" = {
        extraConfig = ''
          if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
          }

          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
        '';
        proxyPass = "http://127.0.0.1:8055";
      };
    };
    virtualHosts."${domain}" = {
      locations."= /" = {
        return = "301 /2023/";
      };
      locations."/" = {
        root = "/srv/web/ese/served";
        tryFiles = "$uri $uri/ =404";
      };
    };
  };
}
