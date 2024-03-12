{ config, ... }:
let
  hostname = "mail.${config.networking.domain}";
in
{
  imports = [
    ./postfix.nix
    ./dovecot2.nix
    ./rspamd.nix
    ./sogo.nix
    ./mailman.nix
  ];

  # Get SSL certs for dovecot and postfix via ngnix
  services.nginx.virtualHosts."${hostname}" = {
    forceSSL = true;
    enableACME = true;
  };
  security.acme.certs."${hostname}" = {
    reloadServices = [
      "postfix.service"
      "dovecot2.service"
    ];
  };
}
