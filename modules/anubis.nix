{ config, nixpkgs-unstable, ... }:
{
  # module on stable is broken
  disabledModules = [ "services/networking/anubis.nix" ];
  imports = [ "${nixpkgs-unstable}/nixos/modules/services/networking/anubis.nix" ];
  # for unix socket permissions
  users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];

  services.anubis.defaultOptions = {
    settings = {
      WEBMASTER_EMAIL = "root@ifsr.de";
    };
  };
}
