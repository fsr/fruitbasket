{ config, lib, pkgs, ... }:
{
  services.fail2ban = {
    enable = true;

    jails = {
      tor = ''
        enabled = true
        bantime = 25h
        action = iptables-allports[name=fail2banTOR, protocol=all]
      '';
      dovecot = ''
        enabled = true
        # aggressive mode to add blocking for aborted connections
        filter = dovecot[mode=aggressive]
        maxretry = 3
      '';
      postfix = ''
        enabled = true
        filter = postfix[mode=aggressive]
        maxretry = 3
      '';
    };
  };

  environment.etc = {
    # dummy filter
    "fail2ban/filter.d/tor.conf".text = ''
      [Definition]
      failregex =
      ignoreregex =
    '';
  };

  systemd.services."fail2ban-tor" = {
    script = ''
      ${lib.getExe pkgs.curl} -fsSL "https://check.torproject.org/torbulkexitlist" | sed '/^#/d' | while read IP; do
        ${config.services.fail2ban.package}/bin/fail2ban-client set "tor" banip "$IP" > /dev/null
      done
    '';
  };

  systemd.timers."fail2ban-tor" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "fail2ban-tor.service";
    };
  };
}
