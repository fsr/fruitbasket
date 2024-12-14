{ pkgs, ... }:
{
  services.rsyslogd = {
    enable = true;
    defaultConfig = ''
      $FileCreateMode 0640
      :programname, isequal, "postfix" /var/log/postfix.log
      :programname, isequal, "portunus" /var/log/portunus.log

      auth.*                          -/var/log/auth.log
    '';
  };
  services.logrotate.configFile = pkgs.writeText "logrotate.conf" ''
    weekly
    missingok
    notifempty
    rotate 4
    "/var/log/postfix.log" {
      compress
      delaycompress
      weekly
      rotate 156
    }
    "/var/log/nginx/*.log" {
      compress
      delaycompress
      weekly
      postrotate
        [ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`
      endscript
      rotate 26
      su nginx nginx
    }
  '';
}
