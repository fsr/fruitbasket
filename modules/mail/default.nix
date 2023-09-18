{ config, pkgs, ... }:
let
  hostname = "mail.${config.networking.domain}";
  domain = config.networking.domain;
  rspamd-domain = "rspamd.${config.networking.domain}";
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
  # see https://www.kuketz-blog.de/e-mail-anbieter-ip-stripping-aus-datenschutzgruenden/
  header_cleanup = pkgs.writeText "header_cleanup_outgoing" ''
    /^\s*(Received: from)[^\n]*(.*)/ REPLACE $1 127.0.0.1 (localhost [127.0.0.1])$2
    /^\s*User-Agent/ IGNORE
    /^\s*X-Enigmail/ IGNORE
    /^\s*X-Mailer/ IGNORE
    /^\s*X-Originating-IP/ IGNORE
    /^\s*Mime-Version/ IGNORE
  '';
in
{
  sops.secrets."rspamd-password".owner = config.users.users.rspamd.name;
  sops.secrets."dovecot_ldap_search".owner = config.services.dovecot2.user;
  sops.secrets."postfix_ldap_aliases".owner = config.services.postfix.user;

  networking.firewall.allowedTCPPorts = [
    25 # insecure SMTP
    143
    465
    587 # SMTP
    993 # IMAP
    4190 # sieve
  ];
  users.users.postfix.extraGroups = [ "opendkim" ];
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

  services = {
    postfix = {
      enable = true;
      enableSubmission = true;
      enableSubmissions = true;
      hostname = "${hostname}";
      domain = "${domain}";
      origin = "${domain}";
      destination = [ "${hostname}" "${domain}" "localhost" ];
      networksStyle = "host"; # localhost and own public IP
      sslCert = "/var/lib/acme/${hostname}/fullchain.pem";
      sslKey = "/var/lib/acme/${hostname}/key.pem";
      relayDomains = [ "hash:/var/lib/mailman/data/postfix_domains" ];
      config = {
        home_mailbox = "Maildir/";
        # hostname used in helo command. It is recommended to have this match the reverse dns entry
        smtp_helo_name = config.networking.rDNS;
        smtp_use_tls = true;
        # smtp_tls_security_level = "encrypt";
        smtpd_use_tls = true;
        # smtpd_tls_security_level = lib.mkForce "encrypt";
        # smtpd_tls_auth_only = true;
        smtpd_tls_protocols = [
          "!SSLv2"
          "!SSLv3"
          "!TLSv1"
          "!TLSv1.1"
        ];
        # "reject_non_fqdn_hostname"
        smtpd_recipient_restrictions = [
          "permit_sasl_authenticated"
          "permit_mynetworks"
          "reject_unauth_destination"
          "reject_non_fqdn_sender"
          "reject_non_fqdn_recipient"
          "reject_unknown_sender_domain"
          "reject_unknown_recipient_domain"
          "reject_unauth_destination"
          "reject_unauth_pipelining"
          "reject_invalid_hostname"
          # "check_policy_service inet:localhost:12340" # disabled since it breaks mails to root@ifsr.de
        ];
        smtpd_relay_restrictions = [
          "permit_sasl_authenticated"
          "permit_mynetworks"
          "reject_unauth_destination"
        ];
        smtp_header_checks = "pcre:${header_cleanup}";
        # smtpd_sender_login_maps = [ "ldap:${ldap-senders}" ];
        alias_maps = [ "hash:/etc/aliases" ];
        alias_database = [ "hash:/etc/aliases" ];
        # alias_maps = [ "hash:/etc/aliases" "ldap:${ldap-aliases}" ];
        smtpd_milters = [ "local:/run/opendkim/opendkim.sock" ];
        non_smtpd_milters = [ "local:/var/run/opendkim/opendkim.sock" ];
        smtpd_sasl_auth_enable = true;
        smtpd_sasl_path = "/var/lib/postfix/auth";
        smtpd_sasl_type = "dovecot";
        #mailman stuff
        mailbox_transport = "lmtp:unix:/run/dovecot2/dovecot-lmtp";

        transport_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
        virtual_alias_maps = [ "hash:/var/lib/mailman/data/postfix_vmap" ];
        local_recipient_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" "ldap:${config.sops.secrets."postfix_ldap_aliases".path}" "$alias_maps" ];
      };
    };
    dovecot2 = {
      enable = true;
      enableImap = true;
      enableQuota = true;
      quotaGlobalPerUser = "10G";
      enableLmtp = true;
      mailLocation = "maildir:~/Maildir";
      sslServerCert = "/var/lib/acme/${hostname}/fullchain.pem";
      sslServerKey = "/var/lib/acme/${hostname}/key.pem";
      protocols = [ "imap" "sieve" ];
      mailPlugins = {
        perProtocol = {
          imap = {
            enable = [ "imap_sieve" ];
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
      };
      modules = [
        pkgs.dovecot_pigeonhole
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


        mail_plugins = $mail_plugins listescape
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
    opendkim = {
      enable = true;
      domains = "csl:${config.networking.domain}";
      selector = config.networking.hostName;
      configFile = pkgs.writeText "opendkim-config" ''
        UMask 0117
      '';
    };
    rspamd = {
      enable = true;
      postfix.enable = true;
      locals = {
        "worker-controller.inc".source = config.sops.secrets."rspamd-password".path;
        "redis.conf".text = ''
          read_servers = "127.0.0.1";
          write_servers = "127.0.0.1";
        '';
        # headers in spamassasin style to not break old sieve scripts
        "worker-proxy.inc".text = ''
          spam_header = "X-Spam-Flag";
        '';
        "milter_headers.conf".text = ''
          use = ["x-spam-level", "x-spam-status"];
        '';
      };
    };
    redis = {
      vmOverCommit = true;
      servers.rspamd = {
        enable = true;
        port = 6379;
      };
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."${hostname}" = {
        forceSSL = true;
        enableACME = true;
      };
      virtualHosts."${rspamd-domain}" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:11334";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
  security.acme.certs."${domain}" = {
    reloadServices = [
      "postfix.service"
      "dovecot2.service"
    ];
  };
}
