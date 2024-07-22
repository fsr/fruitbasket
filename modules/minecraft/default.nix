{ ... }:
{
  services.minecraft-server = {
    enable = true;
    eula = true;
  };

  networking.firewall = {
    extraInputRules = ''
      ip saddr { 141.30.0.0/16, 141.76.0.0/16} tcp dport 25565 accept comment "Allow ldaps access from office nets and podman"
    '';
  };
}
