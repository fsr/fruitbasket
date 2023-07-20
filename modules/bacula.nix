{ pkgs, config, lib, ... }:
with lib;

let
  # We write a custom config file because the upstream config has some flaws
  fd_cfg = config.services.bacula-fd;
  fd_conf = pkgs.writeText "bacula-fd.conf" ''
    Client {
      Name = ${fd_cfg.name}
      FDPort = ${toString fd_cfg.port}
      WorkingDirectory = /var/lib/bacula
      Pid Directory = /run
      ${fd_cfg.extraClientConfig}
    }

    ${concatStringsSep "\n" (mapAttrsToList (name: value: ''
    Director {
      Name = ${name}
      Password = ${value.password}
      Monitor = ${value.monitor}
    }
    '') fd_cfg.director)}

    Messages {
      Name = Standard;
      syslog = all, !skipped, !restored
      ${fd_cfg.extraMessagesConfig}
    }
  '';
in
{
  sops.secrets = {
    "bacula/password".owner = "bacula";
    "bacula/keypair".owner = "bacula";
    "bacula/masterkey".owner = "bacula";
  };
  networking.firewall.allowedTCPPorts = [ config.services.bacula-fd.port ];
  networking.firewall.allowedUDPPorts = [ config.services.bacula-fd.port ];
  services.bacula-fd = {
    enable = true;
    name = "ifsr-quitte";
    extraClientConfig = ''
      Maximum Concurrent Jobs = 20
      FDAddress = 141.30.30.169
      PKI Signatures = Yes
      PKI Encryption = Yes
      PKI Keypair = ${config.sops.secrets."bacula/keypair".path}
      PKI Master Key = ${config.sops.secrets."bacula/masterkey".path}
    '';
    extraMessagesConfig = ''
      director = abel-dir = all, !skipped, !restored
    '';
    director."abel-dir".password = "@${config.sops.secrets."bacula/password".path}";
  };
  environment.etc."bacula/bconsole.conf".text = ''
    Director {
      Name = abel-dir
      DIRport = 9101
      address = 10.144.0.11
      Password = @${config.sops.secrets."bacula/password".path}
    }
    Console {
      Name = ifsr-quitte-console
      Password = @${config.sops.secrets."bacula/password".path}
    }
  '';
  systemd.services.bacula-fd.serviceConfig.ExecStart = lib.mkForce "${pkgs.bacula}/sbin/bacula-fd -f -u root -g bacula -c ${fd_conf}";
}
