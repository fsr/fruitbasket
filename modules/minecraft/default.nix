{ pkgs, config, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "minecraft-server"
  ];
  services.minecraft-servers = {
    enable = true;
    eula = true;
    servers.ifsr = {
      enable = true;
      package = pkgs.fabricServers.fabric-1_21;
      jvmOpts = "-Xmx8192M -Xms8192M";
    };
  };
  services.bluemap = {
    enable = true;
    host = "map.mc.ifsr.de";
    eula = true;
    onCalendar = "hourly";
    defaultWorld = "/srv/minecraft/ifsr/world";
  };
  services.nginx.virtualHosts."map.mc.ifsr.de".extraConfig = ''
    allow 141.30.0.0/16;
    allow 141.76.0.0/16;
    allow 217.160.244.15/32; # jonas uptime kuma
    deny all;
  '';

  networking.firewall = {
    extraInputRules = ''
      ip saddr { 141.30.0.0/16, 141.76.0.0/16, 217.160.244.15/32 } tcp dport 25565 accept comment "Allow minecraft access from TU network and jonas monitoring"
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
        { command = "/run/current-system/sw/bin/systemctl restart minecraft-server-ifsr"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl start minecraft-server-ifsr"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl stop minecraft-server-ifsr"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
