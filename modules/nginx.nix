{ lib, config, pkgs, ... }:
{
  services.nginx =
    let
      # manually write the hosts in here since automatic grabbing leads to an unfixable infinite recursion
      hosts = [ "mail" "rspamd" "chat" "matrix" "kpp" "kurse" "git" "ftp" "users" "pad" "list.pad" "manual" "infoscreen" "kanboard" "kb" "lists" "nc" "oc" "sharepic" "vault" "www" "wiki" ];
    in
    {

      additionalModules = [ pkgs.nginxModules.pam ];
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      # split up nginx access logs per vhost
      virtualHosts = lib.genAttrs (lib.lists.forEach hosts (h: h + ".ifsr.de")) (host: {
        extraConfig = ''
          access_log /var/log/nginx/${host}_access.log;
          error_log /var/log/nginx/${host}_error.log;
        '';
      });

      # appendHttpConfig = ''
      #   map $remote_addr $remote_addr_anon {
      #            ~(?P<ip>\d+\.\d+\.\d+)\.    $ip.0;
      #            ~(?P<ip>[^:]+:[^:]+):       $ip::;
      #            # IP addresses to not anonymize
      #            127.0.0.1                   $remote_addr;
      #            ::1                         $remote_addr;
      #            default                     0.0.0.0;
      #   }
      #   log_format  anon_ip   '$remote_addr_anon - $remote_user [$time_local] "$request" '
      #                         '$status $body_bytes_sent "$http_referer" '
      #                         '"$http_user_agent" "$http_x_forwarded_for"';

      #   access_log  /var/log/nginx/access.log  anon_ip;
      # '';
    };
  security.acme = {
    acceptTerms = true;
    defaults = {
      #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      email = "root@${config.networking.domain}";
    };
  };
  security.pam.services.nginx.text = ''
    auth required ${pkgs.nss_pam_ldapd}/lib/security/pam_ldap.so
    account required ${pkgs.nss_pam_ldapd}/lib/security/pam_ldap.so
  '';
}
