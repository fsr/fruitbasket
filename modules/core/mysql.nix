{ pkgs, ... }:
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings.mysqld.bind_address = "127.0.0.1";
  };
  services.mysqlBackup = {
    enable = true;
    user = "mysql";
    location = "/var/lib/backup/mysql";
    databases = [
      "fsrewsp"
      "nightline"
      "wiki_ese"
      "wiki_vernetzung"
    ];
  };
}
