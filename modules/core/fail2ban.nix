{ ... }:
{
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "141.30.0.0/16"
      "141.76.0.0/16"
    ];
    bantime-increment = {
      enable = true;
    };

    jails = {
      dovecot = ''
        enabled = true
        # aggressive mode to add blocking for aborted connections
        filter = dovecot[mode=aggressive]
        maxretry = 6
      '';
      postfix = ''
        enabled = true
        filter = postfix[mode=aggressive]
        maxretry = 6
      '';
      sshd.settings.maxretry = 15;
    };
  };
}
