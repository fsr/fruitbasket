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

  security.acme.certs."${hostname}" = {
    reloadServices = [
      "postfix.service"
      "dovecot2.service"
    ];
  };
}
