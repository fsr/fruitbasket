{ lib, config, pkgs, ... }:
let
  hostname = "mail.${config.networking.domain}";
  dovecot-ldap-args = pkgs.writeText "ldap-args" ''
    uris = ldap://idm.ifsr.de:3389
    dn = cn=ldap-search,ou=users,dc=ifsr,dc=de
    auth_bind = yes
    !include ${config.sops.secrets."dovecot_ldap_search".path}

    ldap_version = 3
    scope = subtree
    base = dc=ifsr,dc=de
    user_filter = (&(objectClass=posixAccount)(cn=%n))
    pass_filter = (&(objectClass=posixAccount)(cn=%n))
  '';
in
{
  networking.firewall.allowedTCPPorts = [
    993 # IMAPS
    4190 # Managesieve
  ];
  environment.systemPackages = [
    pkgs.dovecot_pigeonhole
  ];

  sops.secrets."dovecot_ldap_search".owner = config.services.dovecot2.user;
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
    # set to satisfy the sieveScripts check, will be overridden by userdb lookups anyways
    mailUser = "vmail";
    mailGroup = "vmail";
    sieve = {
      # just pot something in here to prevent empty strings
      extensions = [ "notify" ];
      pipeBins = map lib.getExe [
        (pkgs.writeShellScriptBin "learn-ham.sh" "exec ${pkgs.rspamd}/bin/rspamc learn_ham")
        (pkgs.writeShellScriptBin "learn-spam.sh" "exec ${pkgs.rspamd}/bin/rspamc learn_spam")
      ];
      plugins = [
        "sieve_imapsieve"
        "sieve_extprograms"
      ];
      scripts = {
        before = pkgs.writeText "spam.sieve" ''
          require "fileinto";

          if anyof(
          header :contains "x-spam-flag" "yes",
          header :contains "X-Spam-Status" "Yes"){
                  fileinto "Spam";
          }
        '';
      };
    };
    imapsieve.mailbox = [
      {
        # Spam: From elsewhere to Spam folder or flag changed in Spam folder
        name = "Spam";
        causes = [ "COPY" "APPEND" "FLAG" ];
        before = ./report-spam.sieve;

      }
      {
        # From Junk folder to elsewhere
        name = "*";
        from = "Spam";
        causes = [ "COPY" ];
        before = ./report-ham.sieve;
      }
    ];
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
        # https://doc.dovecot.org/configuration_manual/plugins/listescape_plugin/
        listescape_char = "\\"
      }
      ssl_min_protocol = TLSv1.2
      ssl_prefer_server_ciphers = no
      ssl_curve_list = X25519:prime256v1:secp384r1
      ssl_cipher_list = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305
    '';
  };
}
