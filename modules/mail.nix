{ config, pkgs, lib, ... }:
let
  hostname = "mail.${config.fsr.domain}";
  domain = config.fsr.domain;
  rspamd-domain = "rspamd.${config.fsr.domain}";
  # brauchen wir das überhaupt?
  #ldap-aliases = pkgs.writeText "ldap-aliases.cf" ''
  #server_host = ldap://localhost
  #search_base = dc=ifsr, dc=de
  #query_filter = (&(objectClass=posixAccount)(uid=%n))
  #result_attribute=mail
  #'';
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
  sops.secrets."rspamd-password".owner = config.users.users.rspamd.name;
  sops.secrets."dovecot_ldap_search".owner = config.services.dovecot2.user;

  networking.firewall.allowedTCPPorts = [ 25 465 587 993 ];
  users.users.postfix.extraGroups = [ "opendkim" ];

  services = {
    postfix = {
      enable = true;
      enableSubmission = true;
      enableSubmissions = true;
      hostname = "${hostname}";
      domain = "${domain}";
      origin = "${domain}";
      destination = [ "${hostname}" "${domain}" "localhost" ];
      networks = [ "127.0.0.1" "141.30.30.169" ];
      sslCert = "/var/lib/acme/${hostname}/fullchain.pem";
      sslKey = "/var/lib/acme/${hostname}/key.pem";
      relayDomains = [ "hash:/var/lib/mailman/data/postfix_domains" ];

      extraAliases = ''
        # Taken from kaki, maybe we can throw out some at some point
        # General redirections for pseudo accounts
        bin:            root
        daemon:         root
        named:          root
        nobody:         root
        uucp:           root
        www:            root
        ftp-bugs:       root
        postfix:        root

        # Well-known aliases
        manager:        root
        dumper:         root
        operator:       root
        abuse:          postmaster

        # trap decode to catch security attacks
        decode:         root
      '';
      config = {
        home_mailbox = "Maildir/";
        smtp_use_tls = true;
        smtp_tls_security_level = "encrypt";
        smtpd_use_tls = true;
        smtpd_tls_security_level = lib.mkForce "encrypt";
        smtpd_tls_auth_only = true;
        smtpd_tls_protocols = [
          "!SSLv2"
          "!SSLv3"
          "!TLSv1"
          "!TLSv1.1"
        ];
        smtpd_recipient_restrictions = [
          "permit_sasl_authenticated"
          "permit_mynetworks"
          "reject_unauth_destination"
          "reject_non_fqdn_hostname"
          "reject_non_fqdn_sender"
          "reject_non_fqdn_recipient"
          "reject_unknown_sender_domain"
          "reject_unknown_recipient_domain"
          "reject_unauth_destination"
          "reject_unauth_pipelining"
          "reject_invalid_hostname"
        ];
        smtpd_relay_restrictions = [
          "permit_sasl_authenticated"
          "permit_mynetworks"
          "reject_unauth_destination"
        ];
        alias_maps = [ "hash:${../config/aliases}" ];
        smtpd_milters = [ "local:/run/opendkim/opendkim.sock" ];
        non_smtpd_milters = [ "local:/var/run/opendkim/opendkim.sock" ];
        smtpd_sasl_auth_enable = true;
        smtpd_sasl_path = "/var/lib/postfix/auth";
        smtpd_sasl_type = "dovecot";
        #mailman stuff
        transport_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
        local_recipient_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
      };
    };
    dovecot2 = {
      enable = true;
      enableImap = true;
      enableQuota = false;
      mailLocation = "maildir:~/Maildir";
      sslServerCert = "/var/lib/acme/${hostname}/fullchain.pem";
      sslServerKey = "/var/lib/acme/${hostname}/key.pem";
      mailboxes = {
        Spam = {
          auto = "create";
          specialUse = "Junk";
        };
        Sent = {
          auto = "create";
          specialUse = "Sent";
        };
        Drafts = {
          auto = "create";
          specialUse = "Drafts";
        };
        Trash = {
          auto = "create";
          specialUse = "Trash";
        };
      };
      extraConfig = ''
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
      '';
    };
    opendkim = {
      enable = true;
      domains = "csl:${config.fsr.domain}";
      selector = config.networking.hostName;
      configFile = pkgs.writeText "opendkim-config" ''
        UMask                   0117
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
