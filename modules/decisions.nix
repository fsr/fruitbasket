{ config, pkgs, ... }:
let
  domain = "decisions.${config.networking.domain}";
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers.decicions = {
      image = "decisions";
      volumes = [
        "/var/lib/nextcloud/data/root/files/FSR/protokolle:/protokolle:ro"
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
