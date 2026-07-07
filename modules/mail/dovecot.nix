{ lib, config, pkgs, ... }:
let
  hostname = "mail.${config.networking.domain}";
in
{
  networking.firewall.allowedTCPPorts = [
    993 # IMAPS
    4190 # Managesieve
  ];
  environment.systemPackages = [
    pkgs.dovecot_pigeonhole
  ];

  sops.secrets."dovecot_ldap_search" = {
    key = "ldap/search-password";
  };
  services.dovecot2 = {
    enable = true;
    package = pkgs.dovecot;
    sieve.pipeBins = (map lib.getExe [
      (pkgs.writeShellScriptBin "learn-ham.sh" "exec ${pkgs.rspamd}/bin/rspamc learn_ham")
      (pkgs.writeShellScriptBin "learn-spam.sh" "exec ${pkgs.rspamd}/bin/rspamc learn_spam")
    ]);

    settings = {

      dovecot_config_version = "2.4.3";
      dovecot_storage_version = "2.4.3";
      auth_allow_cleartext = false;
      auth_username_format = "%{user | username | lower}";
      mail_driver = "maildir";
      mail_path = "~/Maildir";
      mailbox_list_storage_escape_char = "%";
      protocols = "imap sieve imap lmtp";
      ssl = "required";
      ssl_min_protocol = "TLSv1.2";
      ssl_server_prefer_ciphers = "client";
      ssl_curve_list = "X25519MLKEM768:X25519:prime256v1:secp384r1";
      ssl_cipher_list = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305";
      "ssl_server" = {
        cert_file = "/var/lib/acme/${hostname}/fullchain.pem";
        key_file = "/var/lib/acme/${hostname}/key.pem";
      };
      "namespace inbox" = {
        inbox = true;
        separator = "/";
        "mailbox Archive" = {
          auto = false;
          special_use = "\\Archive";
        };
        "mailbox Drafts" = {
          auto = "create";
          special_use = "\\Drafts";
        };
        "mailbox Sent" = {
          auto = "create";
          special_use = "\\Sent";
        };
        "mailbox Spam" = {
          auto = "create";
          special_use = "\\Junk";
          "sieve_script script-1" = {
            cause = "COPY,APPEND,FLAG";
            driver = "file";
            path = ./report-spam.sieve;
            type = "before";
          };
        };
        "mailbox Trash" = {
          auto = "create";
          special_use = "\\Trash";
        };

        "imapsieve_from Spam" = {
          "sieve_script ham" = {
            cause = "COPY";
            driver = "file";
            path = ./report-ham.sieve;
            type = "before";
          };
        };
      };

      ldap_uris = "ldap://idm.ifsr.de:3389";
      ldap_auth_dn = "cn=ldap-search,ou=users,dc=ifsr,dc=de";
      ldap_auth_dn_password = "<${config.sops.secrets."dovecot_ldap_search".path}";
      ldap_base = "dc=ifsr,dc=de";
      "passdb ldap" = {
        ldap_filter = "(&(objectClass=posixAccount)(uid=%{user}))";
        ldap_bind = true;
      };
      "userdb ldap" = {
        ldap_filter = "(&(objectClass=posixAccount)(uid=%{user}))";
        fields = {
          home = "%{ldap:homeDirectory}";
          uid = "%{ldap:uidNumber}";
          gid = "%{ldap:gidNumber}";
        };
      };

      "protocol imap" = {
        mail_plugins = {
          imap_filter_sieve = true;
          imap_sieve = true;
          quota = true;
        };
      };

      "protocol lmtp" = {
        mail_plugins = {
          sieve = true;
        };
      };
      sieve_plugins = {
        sieve_imapsieve = true;
        sieve_extprograms = true;
      };
      sieve_global_extensions = {
        "vnd.dovecot.pipe" = true;
      };
      "sieve_script sort-spam" = {
        driver = "file";
        path = pkgs.writeText "spam.sieve" ''
          require "fileinto";

          if anyof(
          header :contains "x-spam-flag" "yes",
          header :contains "X-Spam-Status" "Yes"){
                  fileinto "Spam";
          }
        '';
        type = "before";
      };

      "service managesieve-login" = {
        restart_request_count = 1;
        "inet_listener sieve" = {
          port = 4190;
        };
      };
      "service auth" = {
        user = "root";

        "unix_listener /var/lib/postfix/auth" = {
          group = "postfix";
          mode = 0660;
          user = "postfix";
        };
      };
      "service lmtp" = {
        client_limit = 1;

        "unix_listener dovecot-lmtp" = {
          group = "postfix";
          mode = 0660;
          user = "postfix";
        };
      };
      "mail_plugins" = {
        quota = true;
      };
      quota_storage_size = "10G";
      quota_status_nouser = "DUNNO";
      quota_status_overquota = "552 5.2.2 Mailbox is full";
      quota_status_success = "DUNNO";
      "service quota-status" = {
        executable = "quota-status -p postfix";
        "inet_listener quota-status" =  {
          port = 12340;
        };
        client_limit = 1;
      };

    };
  };
}
