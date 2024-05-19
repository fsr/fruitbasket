{ config, pkgs, ... }:
let
  domain = "kanboard.${config.networking.domain}";
  domain_short = "kb.${config.networking.domain}";
in
{
  sops.secrets."kanboard_env" = { };


  # Podman
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers = {
    containers.kanboard = {
      image = "ghcr.io/kanboard/kanboard:v1.2.35";
      volumes = [
        "kanboard_data:/var/www/app/data"
        "kanboard_plugins:/var/www/app/plugins"
      ];
      ports = [ "127.0.0.1:8045:80" ];
      environmentFiles = [
        config.sops.secrets."kanboard_env".path
      ];
    };
  };

  services.nginx = {
    virtualHosts."${domain_short}" = {
      locations."/".return = "301 $scheme://${domain}$request_uri";
    };

    virtualHosts."${domain}" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8045";
      };
    };
  };
}
