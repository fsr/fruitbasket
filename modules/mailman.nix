{ config, ... }:
{
  services.mailman = {
    enable = true;
    serve.enable = true;
    webHosts = [ "lists.${config.fsr.domain}" ];
    hyperkitty.enable = true;
    enablePostfix = true;
    siteOwner = "root@${config.fsr.domain}";
  };
}
