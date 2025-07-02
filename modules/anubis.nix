{ config, ... }:
{
  # for unix socket permissions
  users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];

  services.anubis.defaultOptions = {
    settings = {
      WEBMASTER_EMAIL = "root@ifsr.de";
    };
  };
}
