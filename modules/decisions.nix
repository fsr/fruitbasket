{ config, pkgs, ... }:
let
  domain = "decisions.${config.networking.domain}";
in
{
  sops.secrets."decisions_env" = { };
  virtualisation.oci-containers = {
    containers.decisions = {
      image = "decisions";
      volumes = [
        "/var/lib/nextcloud/data/root/files/FSR/protokolle:/protokolle:ro"
      ];
      environmentFiles = [
        config.sops.secrets."decisions_env".path
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
    };
  };

  services.portunus.dex.oidcClients = [{
    id = "decisions";
    callbackURL = "https://decisions.ifsr.de/auth";
  }];

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
