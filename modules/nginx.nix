{ config, pkgs, ... }:
{
  services.nginx.enable = true;
  security.acme = {
    acceptTerms = true;
    defaults = {
      #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      email = "root@ifsr.de";
    };
  };
}
