{config, pkgs, ... }:
let
	hostname = "webmail.${config.fsr.domain}";
	domain = config.fsr.domain;
	
in
{
	services = {
		sogo = {
			enable = true;
			language = "German";
			extraConfig = "
				WOWorkersCount = 10;
				SOGoUserSources = ({
					type = ldap;
					CNFieldName = cn;
					UIDFieldName = uid;
					baseDN = "ou = users, dc=ifsr, dc=de";
					bindDN = "uid=search, ou=users, dc=ifsr, dc=de";
					bindPassword = qwertz;
					hostname = "ldap://localhost";
				});		
	
			";
		}
		postgresql = {
			enable = true;
		}
		
	}

