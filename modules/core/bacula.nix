{ pkgs, config, ... }:
{
  sops.secrets = {
    "bacula/password".owner = "bacula";
    "bacula/keypair".owner = "bacula";
    "bacula/masterkey".owner = "bacula";
  };
  networking.firewall = {
    extraInputRules = ''
      ip saddr 10.144.0.11 tcp dport ${builtins.toString config.services.bacula-fd.port} accept comment "Only allow Bacula access from Abel"
    '';
  };
  services.bacula-fd = {
    enable = true;
    name = "ifsr-quitte";
    extraClientConfig = ''
      Comm Compression = no
      Maximum Concurrent Jobs = 20
      FDAddress = 141.30.30.194
      PKI Signatures = Yes
      PKI Encryption = Yes
      PKI Keypair = ${config.sops.secrets."bacula/keypair".path}
      PKI Master Key = ${config.sops.secrets."bacula/masterkey".path}
    '';
    extraMessagesConfig = ''
      director = abel-dir = all, !skipped, !restored
      mailcommand = "${pkgs.bacula}/bin/bsmtp -f \"Bacula <bacula@${config.networking.domain}>\" -s \"Bacula report" %r"
      mail = root+backup = all, !skipped
    '';
    director."abel-dir" = {
      password = "@${config.sops.secrets."bacula/password".path}";
      tls.enable = false;
    };
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
}
