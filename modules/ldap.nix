{config, ...}: let
  # temporary url, zum testen auf laptop zuhause
  tld = "moe";
  hostname = "eisvogel";
  domain = "portunus.${hostname}.${tld}";
in {
  # TODO: acme/letsencrypt oder andere lösung?
  #
  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/".proxyPass = "http://localhost:${toString config.services.portunus.port}";
        "/dex".proxyPass = "http://localhost:${toString config.services.portunus.dex.port}";
      };
    };
  };

  services.portunus = {
    enable = true;
    domain = "${domain}";
    ldap = {
      suffix = "dc=${hostname},dc=${tld}";
      tls = true;
    };

    # TODO: siehe unten sops, statische config
    # seedPath = "";

    # falls wir das brauchen
    # dex = {
    #   enable = true;
    #   ...
    # };
    # searchUserName = "xxx";
  };

  users.ldap = {
    enable = true;
    server = "ldaps://${domain}";
    base = "dc=${hostname},dc=${tld}";
    # useTLS = true; # nicht noetig weil ldaps domain festgelegt. wuerde sonst starttls auf port 389 versuchen
  };

  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
    636 # ldaps
  ];
  # TODO: sops zeug, keine ahnung wie das (ordentlich) gemacht wird/gemacht werden soll
}
