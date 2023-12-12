{ config, ...}:
{
  sops.secrets = {
    "sssd/env"= {};

  };
  services.sssd = {
    enable = true;
    environmentFile = config.sops.secrets."sssd/env".path;
    sshAuthorizedKeysIntegration = true;
    config = ''
      [sssd]
      config_file_version = 2
      services = nss, pam, ssh
      domains = ldap

      [ssh]

      [nss]

      [pam]

      [domain/ldap]
      auth_provider = ldap
      ldap_uri = ldaps://auth.ifsr.de
      ldap_default_authtok_type = password
      ldap_default_authtok = $SSSD_LDAP_DEFAULT_AUTHTOK
      ldap_search_base = dc=ifsr,dc=de
      id_provider = ldap
      ldap_default_bind_dn = uid=search,ou=users,dc=ifsr,dc=de
      cache_credentials = True
      ldap_tls_cacert = /etc/ssl/certs/ca-bundle.crt
      ldap_tls_reqcert = hard
    '';
    
  };
  security.pam.services.sshd.makeHomeDir = true;
}