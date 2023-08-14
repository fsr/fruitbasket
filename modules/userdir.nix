{ config, lib, pkgs, ... }:
let
  domain = "users.${config.fsr.domain}";
  port = 8083;
  apacheUser = config.services.httpd.user;
in
{
  # home directory setup
  systemd.tmpfiles.rules = [
    "d /etc/skel"
  ];
  environment.extraInit = /*sh*/ ''
    if [[ "$HOME" != "/" && "$UID" != 0 ]]; then
      umask 002

      # home dir: apache may traverse only, creation mode is rw(x)------
      setfacl -m u:${apacheUser}:x,d:u::rwx,d:g::-,d:o::- $HOME

      mkdir -p $HOME/public_html
      # public_html dir: apache and $USER have rwx on everything inside
      setfacl -m u:${apacheUser}:rwx,d:u:${apacheUser}:rwx,d:u:$USER:rwx $HOME/public_html
    fi
  '';

  services.httpd = {
    enable = true;
    enablePHP = true;

    virtualHosts.${domain} = {
      enableUserDir = true;
      extraConfig = ''
        <Directory "/home/*/public_html">
          Options -Indexes
          DirectoryIndex index.php index.html
          AllowOverride FileInfo AuthConfig Limit Indexes Options=Indexes
        </Directory>
      '';
      listen = [{
        ip = "127.0.0.1";
        inherit port;
      }];
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://localhost:${toString port}";
    };
  };
}