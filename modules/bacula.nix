{ config, ... }:
{
  sops.secrets = {
    "bacula/password".owner = "bacula";
    "bacula/keypair".owner = "bacula";
    "bacula/masterkey".owner = "bacula";
  };
  services.bacula-fd = {
    enable = true;
    name = "ifsr-quitte";
    extraClientConfig = ''
      WorkingDirectory = /var/lib/bacula
      Pid Directory = /run/bacula
      Maximum Concurrent Jobs = 20
      FDAddress = 141.30.30.169
      PKI Signatures = Yes
      PKI Encryption = Yes
      PKI Keypair = ${config.sops.secrets."bacula/keypair".path}
      PKI Master Key = ${config.sops.secrets."bacula/masterkey".path}
    '';
    extraMessagesConfig = ''
      Name = Standard
      directory = abel-dir = all, !skipped, !restored
    '';
    director."abel-dir".password = "@${config.sops.secrets."bacula/password".path}";
  };
  environment.etc."bacula/bconsole.conf".text = ''
    Director {
      Name = abel-dir
      DIRport = 9101
      address = 10.144.0.11
      Password = @${config.sops.secrests."bacula/password".path}
    }
    Console {
      Name = ifsr-quitte-console
      Password = @${config.sops.secrests."bacula/password".path}
    }
  '';
}
