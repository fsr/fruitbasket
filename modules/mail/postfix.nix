{ config, pkgs, ... }:
let
  domain = config.networking.domain;
  hostname = "mail.${config.networking.domain}";
  # see https://www.kuketz-blog.de/e-mail-anbieter-ip-stripping-aus-datenschutzgruenden/
  header_cleanup = pkgs.writeText "header_cleanup_outgoing" ''
    /^\s*(Received: from)[^\n]*(.*)/ REPLACE $1 127.0.0.1 (localhost [127.0.0.1])$2
    /^\s*User-Agent/ IGNORE
    /^\s*X-Enigmail/ IGNORE
    /^\s*X-Mailer/ IGNORE
    /^\s*X-Originating-IP/ IGNORE
    /^\s*Mime-Version/ IGNORE
  '';
  # https://unix.stackexchange.com/questions/294300/postfix-prevent-users-from-changing-the-real-e-mail-address
  login_maps = pkgs.writeText "login_maps.pcre" ''
    # basic username => username@ifsr.de
    /^([^@+]*)(\+[^@]*)?@ifsr\.de$/ ''${1}
  '';
in
{
  sops.secrets."postfix_ldap_aliases".owner = config.services.postfix.user;

  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    465 # Submissions
    587 # Submission
  ];
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
      config = {
        home_mailbox = "Maildir/";
        # 25 MiB
        message_size_limit = "26214400";
        mynetworks = ["[::1]/128" "127.0.0.0/8" "10.0.0.0/8""141.30.30.194/32" "[fe80::]/64" "[2a13:dd85:b23:1::]/64"];
        # hostname used in helo command. It is recommended to have this match the reverse dns entry
        smtp_helo_name = config.networking.rDNS;
        smtpd_banner = "${config.networking.rDNS} ESMTP $mail_name";
        smtp_tls_security_level = "may";
        smtpd_tls_security_level = "may";
        smtpd_tls_auth_only = true;
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
          "check_policy_service inet:localhost:12340"
        ];
        smtpd_relay_restrictions = [
          "permit_sasl_authenticated"
          "permit_mynetworks"
          "reject_unauth_destination"
        ];
        # https://www.postfix.org/smtp-smuggling.html
        smtpd_data_restrictions = [
          "reject_unauth_pipelining"
        ];
        smtpd_sender_restrictions = [
          "permit_mynetworks"
          "reject_authenticated_sender_login_mismatch"
          "reject_unauthenticated_sender_login_mismatch"
        ];
        smtpd_sender_login_maps = [
          "pcre:/etc/special-aliases.pcre"
          "pcre:${login_maps}"
        ];
        smtp_header_checks = "pcre:${header_cleanup}";
        # smtpd_sender_login_maps = [ "ldap:${ldap-senders}" ];
        alias_maps = [ "hash:/etc/aliases" ];
        alias_database = [ "hash:/etc/aliases" ];
        # alias_maps = [ "hash:/etc/aliases" "ldap:${ldap-aliases}" ];
        smtpd_sasl_auth_enable = true;
        smtpd_sasl_path = "/var/lib/postfix/auth";
        smtpd_sasl_type = "dovecot";
        local_recipient_maps = [ "ldap:${config.sops.secrets."postfix_ldap_aliases".path}" "$alias_maps" ];
      };
    };
  };
}
