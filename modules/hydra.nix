{ config, ... }:
let
  domain = "hydra.ifsr.de";
in
{
  sops.secrets."hydra_ldap_search".owner = "hydra";
  services.hydra = {
    enable = true;
    port = 4000;
    hydraURL = domain;
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
    extraConfig = ''
            ldap>
        <config>
          <credential>
            class = Password
            password_field = password
            password_type = self_check
          </credential>
          <store>
            class = LDAP
            ldap_server = localhost
            <ldap_server_options>
              timeout = 30
            </ldap_server_options>
            binddn = "cn=search,dc=ifsr,dc=de"
            include ${config.sops.secrets.hydra_ldap_search.path}
            start_tls = 0
            <start_tls_options>
              verify = none
            </start_tls_options>
            user_basedn = "ou=users,dc=ifsr,dc=de"
            user_filter = "(&(objectClass=posixAccount)(cn=%s))"
            user_scope = one
            user_field = cn
            <user_search_options>
              deref = always
            </user_search_options>
            # Important for role mappings to work:
            use_roles = 1
            role_basedn = "ou=groups,dc=ifsr,dc=de"
            role_filter = "(&(objectClass=groupOfNames)(member=%s))"
            role_scope = one
            role_field = cn
            role_value = dn
            <role_search_options>
              deref = always
            </role_search_options>
        </config>
        <role_mapping>
          # Make all users in the hydra_admin group Hydra admins
          admins = admin
        </role_mapping>
      </ldap>
    '';

  };
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
    };
  };
}
