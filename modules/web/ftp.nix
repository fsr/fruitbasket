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
      charset utf-8;
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
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>403 Forbidden - iFSR</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                    background-color: #f8f9fa;
                    margin: 0;
                    padding: 1rem;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .container {
                    background: white;
                    padding: 2rem;
                    border-radius: 12px;
                    box-shadow: 0 2px 15px rgba(0, 0, 0, 0.1);
                    text-align: center;
                    max-width: 600px;
                    width: 100%;
                }
                .error-code {
                    font-size: 3.5rem;
                    font-weight: bold;
                    color: #dc3545;
                    margin: 0;
                    line-height: 1;
                }
                .error-title {
                    font-size: 1.5rem;
                    color: #343a40;
                    margin: 1rem 0;
                }
                .error-message {
                    color: #495057;
                    margin: 1rem 0;
                    line-height: 1.6;
                }
                .language-section {
                    padding: 1.5rem;
                    margin: 1rem 0;
                    background: #f8f9fa;
                    border-radius: 8px;
                    text-align: left;
                }
                .language-header {
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                    font-weight: bold;
                    margin-bottom: 1rem;
                    color: #343a40;
                }
                .help-list {
                    margin: 0;
                    padding-left: 1.2rem;
                    list-style-type: none;
                }
                .help-list li {
                    margin: 0.5rem 0;
                    position: relative;
                }
                .help-list li:before {
                    content: "•";
                    position: absolute;
                    left: -1.2rem;
                    color: #6c757d;
                }
                .logo {
                    width: 180px;
                    height: auto;
                    margin-bottom: 1.5rem;
                }
                @media (max-width: 480px) {
                    .container {
                        padding: 1.5rem;
                    }
                    .language-section {
                        padding: 1rem;
                        margin: 0.5rem 0;
                    }
                    .error-code {
                        font-size: 3rem;
                    }
                    .error-title {
                        font-size: 1.25rem;
                    }
                    .logo {
                        width: 150px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <img src="https://ifsr.de/user/themes/ifsr/images/logo.svg" alt="iFSR Logo" class="logo">
                <h1 class="error-code">403</h1>
                <h2 class="error-title">Zugriff verweigert / Access Forbidden</h2>
                
                <div class="language-section">
                    <div class="language-header">
                        🇩🇪 Deutsch
                    </div>
                    <p class="error-message">
                        Dieser Ordner ist nur aus dem Uni-Netz zugänglich.
                    </p>
                    <ul class="help-list">
                        <li>Stellen Sie sicher, dass Sie mit dem TUD-Netzwerk verbunden sind</li>
                        <li>Oder wählen Sie sich über VPN ein</li>
                    </ul>
                </div>

                <div class="language-section">
                    <div class="language-header">
                        🇬🇧 English
                    </div>
                    <p class="error-message">
                        This directory is only accessible from the TUD network.
                    </p>
                    <ul class="help-list">
                        <li>Make sure you are connected to the TUD network</li>
                        <li>Or connect via VPN</li>
                    </ul>
                </div>
            </div>
        </body>
        </html>
      '';
    };
  };
}
