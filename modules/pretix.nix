{ config, ... }:
let
  domain = "events.${config.networking.domain}";
in
{
  # sops.secrets.pretix_env = {
  #   owner = "pretix";
  # };

  services.pretix = {
    enable = true;


    nginx = {
      enable = true;
      domain = domain;
    };

    settings = {
      pretix = {
        instance_name = "iFSR Events";
        url = "https://${domain}";
        currency = "EUR";
        registration = false;
      };

      mail = {
        from = "events@${config.networking.domain}";
        host = "127.0.0.1";
        port = 25;
      };
    };
  };
}
