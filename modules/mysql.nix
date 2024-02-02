{ pkgs, ... }:
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings.mysqld.bind_address = "127.0.0.1";
  };
}
