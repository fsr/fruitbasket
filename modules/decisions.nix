{ config, pkgs, ... }:
let
  domain = "decisions.${config.networking.domain}";
in
{
  sops.secrets."decisions_env" = { };
  virtualisation.oci-containers = {
    containers.decisions = {
      image = "ghcr.io/fsr/decisions";
      volumes = [
        "/var/lib/nextcloud/data/root/files/FSR/protokolle:/protokolle:ro"
      ];
      extraOptions = [ "--network=host" ];
      environmentFiles = [
        config.sops.secrets."decisions_env".path
      ];
    };
  };

  services.nginx = {
    virtualHosts."${domain}" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:5055";
      };
    };
  };

  systemd.timers."decisions-to-db" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "01:11:00";
      Unit = "decisions-to-db.service";
    };
  };

  systemd.services."decisions-to-db" = {
    script = ''
      set -eu
      ${pkgs.docker}/bin/docker exec decisions python tex_to_db.py
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
