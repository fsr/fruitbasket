{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 3;
        uboot.enable = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # No ZFS on latest kernel:
    tmpOnTmpfs = true;
  };

  networking = {
    hostName = "sanddorn";

    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    firewall.enable = false;
  };

  # Do not log to flash:
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "21.11"; 
}

