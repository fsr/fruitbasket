{ config, pkgs, ... }:
let
  domain = "cc.${config.networking.domain}";
in
{
    services.nginx.virtualHosts."${domain}".root = "/srv/web/regex";
}
