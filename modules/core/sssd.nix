{ config, ... }:
{
  sops.secrets = {
    "sssd/env" = { };

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
      filter_groups = root
      filter_users = root

      [pam]

      [domain/ldap]
      auth_provider = ldap
      id_provider = ldap
      chpass_provider = ldap
      auth_provider = ldap
      access_provider = ldap
      cache_credentials = True

      ldap_uri = ldap://idm.ifsr.de:3389
      ldap_id_use_start_tls = false
      ldap_schema = rfc2307bis
      ldap_search_base = dc=ifsr,dc=de
      ldap_user_object_class = user
      ldap_user_name = cn
      ldap_group_object_class = group
      ldap_group_name = cn
      
      ldap_default_bind_dn = cn=ldap-search,ou=users,dc=ifsr,dc=de
      ldap_default_authtok_type = password
      ldap_default_authtok = $SSSD_LDAP_DEFAULT_AUTHTOK
    '';

  };
  security.pam.services = {
    sshd.makeHomeDir = true;
    login.makeHomeDir = true;
  };
}
