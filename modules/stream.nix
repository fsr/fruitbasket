{pkgs, lib, config, ...}: 
let 
  website = pkgs.fetchgit {
    url = "ssh+git://git@github.com:fsr/fruitbasket.git";
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
              root = "${../content/ese-stream/files/website}/";
              proxyWebsockets = true;
            };
          };
          "stream.ifsr.de" = {
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
        streamConfig = ''
          server {
		listen            1935;
		proxy_pass        [::1]:1935;
		proxy_buffer_size 32k;
	  }
        '';
      };
      owncast = {
        enable = true;
        port = 13142;
	listen = "[::ffff:127.0.0.1]";
	openFirewall = true;
	rtmp-port = 1935;
      };
  };
}
