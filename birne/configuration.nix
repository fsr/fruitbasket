# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      <modules/base.nix>
      <modules/desktop.nix>
      <modules/printing.nix>
    ];

  # setup the NIX_PATH so modules from the repo found
  nix.nixPath = [
   "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
   "nixos-config=/etc/nixos/configuration.nix"
   "/nix/var/nix/profiles/per-user/root/channels"
   "/var/src/fruitbasket"
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

   # Set your time zone.
  time.timeZone = "Europe/Berlin";

  networking.hostName = "birne"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.nameservers = [ "9.9.9.9" "1.1.1.1" ];

  # allow brightness control
  services.illum.enable = true;

  # Define the print user account
  users.users.print = {
    createHome = true;
    isNormalUser = true;
    extraGroups = [ "video" "audio" "dialout" ];
    group = "users";
    home = "/home/print";
    shell = pkgs.fish;
    password = "print";
  };
  services.openssh.extraConfig = "DenyUsers	print";

  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "print";
  };

  # TODO: systemd-service for clearing the Downloads folder @midnight
  # TODO: chmod 500 Desktop

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

