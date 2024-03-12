{ ... }:
{
  imports = [
    ./base.nix
    ./bacula.nix
    ./fail2ban.nix
    ./initrd-ssh.nix
    ./mysql.nix
    ./nginx.nix
    ./postgres.nix
    ./sssd.nix
    ./zsh.nix
  ];
}
