{ config, pkgs, ... }:
    let
        hostname  = "mail.test.stramke.com";
        domain = "test.stramke.com";
    in {
        networking.firewall.allowedTCPPorts = [ 25 587 143 ];
        services = {
            postfix = {
                enable = true; 
                hostname = "${hostname}";
                domain = "${domain}";
                relayHost = "";
                origin = "${domain}";
                destination = ["${hostname}" "${domain}" "localhost"];
                config = {
                    mynetworks = "168.119.135.69/32 10.0.0.0/24 0.0.0.0/0 127.0.0.1";
                    smtpd_recipient_restrictions = [
                       "reject_unauth_destination"
                       "permit_sasl_authenticated"
                       "permit_mynetworks"
                    ];
                    smtpd_sasl_auth_enable = true;
                    smtpd_sasl_path = "/var/lib/postfix/auth";
                    # smtpd_sasl_type = "dovecot";
                };
            };
            dovecot2 = {
                enable = true;
                enableImap = true;
                enableQuota = false;
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
                    mail_location = maildir:/var/spool/mail/%u
                    auth_mechanisms = plain login
                    disable_plaintext_auth = no
                    userdb {
                        driver = passwd
                        args = blocking=no
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
            rspamd = {
                enable = true;
            };
            opendkim = {
                enable = true;
                selector = "mail";
                domains = "csl:${domain}";
            };
        };
    }

