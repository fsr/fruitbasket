{ config, ... }:
{
  services.mailman = {
    enable = true;
    serve.enable = true;
    webHosts = [ "lists.${config.networking.domain}" ];
    hyperkitty.enable = true;
    enablePostfix = true;
    siteOwner = "mailman@${config.networking.domain}";
    settings = {
      database = {
        class = "mailman.database.postgresql.PostgreSQLDatabase";
        url = "postgresql://mailman@/mailman?host=/run/postgresql";
      };
    };
    webSettings = {
      DATABASES.default = {
        ENGINE = "django.db.backends.postgresql";
        NAME = "mailman-web";
      };
      ACCOUNT_EMAIL_UNKNOWN_ACCOUNTS = false;
      ACCOUNT_PREVENT_ENUMERATION = true;
      SOCIALACCOUNT_EMAIL_AUTHENTICATION = true;
      EMAIL_AUTHENTICATION_AUTO_CONNECT = true;

      INSTALLED_APPS = [
        "hyperkitty"
        "postorius"
        "django_mailman3"
        "django.contrib.admin"
        "django.contrib.auth"
        "django.contrib.contenttypes"
        "django.contrib.sessions"
        "django.contrib.sites"
        "django.contrib.messages"
        "django.contrib.staticfiles"
        "django.contrib.humanize"
        "rest_framework"
        "django_gravatar"
        "compressor"
        "haystack"
        "django_extensions"
        "django_q"
        "allauth"
        "allauth.account"
        "allauth.socialaccount"
        "allauth.socialaccount.providers.openid_connect"
      ];
    };
  };
  services.postfix = {
    relayDomains = [ "hash:/var/lib/mailman/data/postfix_domains" ];
    config = {
      mailbox_transport = "lmtp:unix:/run/dovecot2/dovecot-lmtp";
      transport_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
      virtual_alias_maps = [ "hash:/var/lib/mailman/data/postfix_vmap" ];
      local_recipient_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
    };
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "mailman";
        ensureDBOwnership = true;
      }
      {
        name = "mailman-web";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "mailman" "mailman-web" ];
  };
  services.nginx.virtualHosts."lists.${config.networking.domain}" = {
    locations."/accounts/signup" = {
      extraConfig = ''
        allow 141.30.0.0/16;
        allow 141.76.0.0/16;
        deny all;
        uwsgi_pass unix:/run/mailman-web.socket;
      '';
    };
    locations."/robots.txt" = {
      extraConfig = ''
        add_header  Content-Type  text/plain;
        return 200 "User-agent: *\nDisallow: /\n";
      '';
    };
  };
}
