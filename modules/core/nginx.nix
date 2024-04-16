{ lib, config, pkgs, ... }:
{
  # set default options for virtualHosts
  options = with lib; {
    services.nginx.virtualHosts = mkOption {
      type = types.attrsOf (types.submodule
        ({ name, ... }: {
          enableACME = true;
          forceSSL = true;
          # enable http3 for all hosts
          quic = true;
          http3 = true;
          # split up nginx access logs per vhost
          extraConfig = ''
            access_log /var/log/nginx/${name}_access.log;
            error_log /var/log/nginx/${name}_error.log;
            add_header Alt-Svc 'h3=":443"; ma=86400';
          '';
        })
      );
    };
  };

  config = {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    networking.firewall.allowedUDPPorts = [ 443 ];
    services.nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      additionalModules = [ pkgs.nginxModules.pam ];
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

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
  };
}
