{ config, pkgs, ... }:
let
  domain = "ftp.${config.networking.domain}";
in
{
  services.nginx.additionalModules = [ pkgs.nginxModules.fancyindex ];
  services.nginx.virtualHosts."${domain}" = {
    root = "/srv/ftp";
    extraConfig = ''
      fancyindex on;
      fancyindex_exact_size off;
      error_page 403 /403.html;
      fancyindex_localtime on;
    '';
    locations."~/(klausuren|uebungen|skripte|abschlussarbeiten)".extraConfig = ''
      allow 141.30.0.0/16;
      allow 141.76.0.0/16;
      deny all;
    '';
    locations."~ /komplexpruef".extraConfig = ''
      default_type text/plain;
    '';
    locations."=/403.html" = {
      root = pkgs.writeTextDir "403.html" ''
        <html>
          <head>
            <title>403 Forbidden</title>
          </head>
          <body>
            <center><h1>403 Forbidden</h1></center>
            <center>Dieser Ordner ist nur aus dem Uni-Netz zug&aumlnglich.</center>
            <center>This directory is only accessible from the TUD network.</center>
          </body>
        </html>
      '';
    };
  };
}
