{ config, pkgs, ... }:
{
  sops.secrets."strukturbot_env" = { };
  # virtualisation.docker.daemon.settings.dns = [ "141.30.1.1" "141.76.14.1" ];
  virtualisation.oci-containers = {
    containers.struktur-bot = {
      image = "struktur-bot";
      environmentFiles = [
        config.sops.secrets."strukturbot_env".path
      ];
      extraOptions = [ "--network=host" ];
    };
  };
  systemd.timers."overleaf-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:22:00";
      Unit = "overleaf-backup.service";
    };
  };

  systemd.services."overleaf-backup" = {
    script = ''
      set -eu
      ${pkgs.docker}/bin/docker exec struktur-bot python3 backup.py
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
