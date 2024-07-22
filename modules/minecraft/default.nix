{config,  pkgs, lib, nixpkgs-unstable, ... }:
{
  services.minecraft-server = {
    enable = true;
    # hack to enable unstable unfree package
    package = nixpkgs-unstable.legacyPackages.x86_64-linux.minecraft-server.overrideAttrs (_old: { meta.license = [ lib.licenses.mit ]; });
    eula = true;
  };
  services.bluemap = {
    enable = true;
    host = "map.mc.ifsr.de";
    eula = true;
    defaultWorld = "${config.services.minecraft-server.dataDir}/world";
  };
  services.nginx.virtualHosts."map.mc.ifsr.de".extraConfig = ''
    allow 141.30.0.0/16;
    allow 141.76.0.0/16;
    deny all;
  '';

  networking.firewall = {
    extraInputRules = ''
      ip saddr { 141.30.0.0/16, 141.76.0.0/16} tcp dport 25565 accept comment "Allow minecraft access from office nets and podman"
    '';
  };
  users.users.minecraft = {
    isNormalUser = true;
    isSystemUser = lib.mkForce false;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkxTuzjS3EswMfj+wSKu9ciRyStvjDlDUXzkqEUGDaP rouven@thinkpad"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhdjiPvtAo/ZV36RjBBPSlixzeP3VN6cqa4YAmM5uXM ff00005@ff00005-laptop" # malte
    ];
  };
  security.sudo.extraRules = [
    {
      users = [ "minecraft" ];
      commands = [
        { command = "/run/current-system/sw/bin/systemctl restart minecraft-server"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl start minecraft-server"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl stop minecraft-server"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
