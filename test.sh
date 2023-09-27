ldapsearch -o ldif-wrap=no -x -D "uid=search,ou=users,dc=ifsr,dc=de" -w $(cat /run/secrets/portunus/search-password) '(&(objectClass=posixAccount)(uid='rouven.seifert'))' 'sshPublicKey' -b "ou=users,dc=ifsr,dc=de" \
| awk '/^sshPublicKey/{$1=""; p=1} /^$/{p=0} {printf p?$0:""}'
