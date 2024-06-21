{ config, pkgs, ... }:
let
  hostname = "mail.${config.networking.domain}";
  dovecot-ldap-args = pkgs.writeText "ldap-args" ''
    uris = ldap://localhost
    dn = uid=search, ou=users, dc=ifsr, dc=de
    auth_bind = yes
    !include ${config.sops.secrets."dovecot_ldap_search".path}

    ldap_version = 3
    scope = subtree
    base = dc=ifsr, dc=de
    user_filter = (&(objectClass=posixAccount)(uid=%n))
    pass_filter = (&(objectClass=posixAccount)(uid=%n))
  '';
in
{
  networking.firewall.allowedTCPPorts = [
    993 # IMAPS
    4190 # Managesieve
  ];
  sops.secrets."dovecot_ldap_search".owner = config.services.dovecot2.user;
  environment.etc = {
    "dovecot/sieve-pipe/sa-learn-spam.sh" = {
      text = ''
        #!/bin/sh
        ${pkgs.rspamd}/bin/rspamc learn_spam
      '';
      mode = "0555";
    };
    "dovecot/sieve-pipe/sa-learn-ham.sh" = {
      text = ''
        #!/bin/sh
        ${pkgs.rspamd}/bin/rspamc learn_ham
      '';
      mode = "0555";
    };
    "dovecot/sieve/report-spam.sieve" = {
      source = ./report-spam.sieve;
      user = "dovecot2";
      group = "dovecot2";
      mode = "0544";
    };
    "dovecot/sieve/report-ham.sieve" = {
      source = ./report-ham.sieve;
      user = "dovecot2";
      group = "dovecot2";
      mode = "0544";
    };
  };

  services.dovecot2 = {
    enable = true;
    enableImap = true;
    enableQuota = true;
    quotaGlobalPerUser = "10G";
    enableLmtp = true;
    enablePAM = false;
    mailLocation = "maildir:~/Maildir";
    sslServerCert = "/var/lib/acme/${hostname}/fullchain.pem";
    sslServerKey = "/var/lib/acme/${hostname}/key.pem";
    protocols = [ "imap" "sieve" ];
    mailPlugins = {
      globally.enable = [ "listescape" ];
      perProtocol = {
        imap = {
          enable = [ "imap_sieve" "imap_filter_sieve" ];
        };
        lmtp = {
          enable = [ "sieve" ];
        };
      };
    };
    mailboxes = {
      Spam = {
        auto = "subscribe";
        specialUse = "Junk";
        autoexpunge = "60d";
      };
      Sent = {
        auto = "subscribe";
        specialUse = "Sent";
      };
      Drafts = {
        auto = "subscribe";
        specialUse = "Drafts";
      };
      Trash = {
        auto = "subscribe";
        specialUse = "Trash";
      };
      Archive = {
        auto = "no";
        specialUse = "Archive";
      };
    };
    modules = [
      pkgs.dovecot_pigeonhole
    ];
    # set to satisfy the sieveScripts check, will be overridden by userdb lookups anyways
    mailUser = "vmail";
    mailGroup = "vmail";
    sieve.scripts = {
      before = pkgs.writeText "spam.sieve" ''
        require "fileinto";

        if anyof(
        header :contains "x-spam-flag" "yes",
        header :contains "X-Spam-Status" "Yes"){
                fileinto "Spam";
        }
      '';
    };
    extraConfig = ''
      auth_username_format = %Ln
      passdb {
        driver = ldap
        args = ${dovecot-ldap-args}
      }
      userdb {
        driver = ldap
        args = ${dovecot-ldap-args}
      }
      service auth {
        unix_listener /var/lib/postfix/auth {
          group = postfix
          mode = 0660
          user = postfix
        }
      }
      service managesieve-login {
        inet_listener sieve {
          port = 4190
        }
        service_count = 1
      }

      namespace inbox {
        separator = /
        inbox = yes
      }

      service lmtp {
        unix_listener dovecot-lmtp {
          group = postfix
          mode = 0600
          user = postfix
        }
        client_limit = 1
      }


      plugin {
        sieve_plugins = sieve_imapsieve sieve_extprograms
        sieve_global_extensions = +vnd.dovecot.pipe
        sieve_pipe_bin_dir = /etc/dovecot/sieve-pipe

        # Spam: From elsewhere to Spam folder or flag changed in Spam folder
        imapsieve_mailbox1_name = Spam
        imapsieve_mailbox1_causes = COPY APPEND FLAG
        imapsieve_mailbox1_before = file:/etc/dovecot/sieve/report-spam.sieve

        # Ham: From Spam folder to elsewhere
        imapsieve_mailbox2_name = *
        imapsieve_mailbox2_from = Spam
        imapsieve_mailbox2_causes = COPY
        imapsieve_mailbox2_before = file:/etc/dovecot/sieve/report-ham.sieve

        # https://doc.dovecot.org/configuration_manual/plugins/listescape_plugin/
        listescape_char = "\\"
      }
    '';
  };
}
