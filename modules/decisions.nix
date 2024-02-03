{ config, pkgs, ... }:
let
  domain = "decisions.${config.networking.domain}";
in
{
  sops.secrets."decisions_env" = { };
  virtualisation.oci-containers = {
    containers.decicions = {
      image = "decisions";
      volumes = [
        "/var/lib/nextcloud/data/root/files/FSR/protokolle:/protokolle:ro"
      ];
      environmentFiles = [
        config.sops.secrets."strukturbot_env".path
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  services.nginx = {
    virtualHosts."${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5055";
      };
      extraConfig = ''
        auth_pam "LDAP Authentication Required";
        auth_pam_service_name "nginx";
      '';
    };
  };
}
