{ config, lib, pkgs, ... }:

{
  # provide access to iLO of colocated server
  # in case of questions, contact @bennofs
  services.nginx.virtualHosts."hyperilo.deutschland.gmbh" = {
    forceSSL = true;
    locations."/".proxyPass = "https://192.168.0.120:443";
    locations."/".basicAuthFile = "/run/secrets/hyperilo_htaccess";
    locations."/".extraConfig = ''
      proxy_ssl_verify off;
    '';
  };

  systemd.network.networks."20-hyperilo" = {
    matchConfig.Name = "eno8303";
    address = [ "192.168.0.1/24" ];
    networkConfig.LLDP = true;
    networkConfig.EmitLLDP = "nearest-bridge";
  };

  sops.secrets."hyperilo_htaccess".owner = "nginx";
}
