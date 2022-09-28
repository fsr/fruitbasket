{pkgs, lib, config, ...}: 
let 
  website = pkgs.fetchFromGitHub {
    owner = "fsr";
    repo = "ese20-ansible";
    rev = "1b380f3bfd48aae2a17aefbbdd0538f09b7d3bcf";
    sha256 = "";
  };
in {
  services = {
    nginx = {
      virtualHosts = {
        "stream-frontend.quitte.tassilo-tanneberger.de" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              root = "${website}/roles/stream_frontend/";
              proxyWebsockets = true;
            };
          };
          "owncast.quitte.tassilo-tanneberger.de" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = let 
              cfg = config.services.owncast;  
            in {
              proxyPass = "http://${toString cfg.listen}:${toString cfg.port}";
              proxyWebsockets = true;
            };
          };
        };
      };
      owncast = {
        enable = true;
      };
  };
}
