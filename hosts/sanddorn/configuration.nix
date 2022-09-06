{ config, lib, pkgs, ... }:
{
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

  nix = {
    autoOptimiseStore = true;
  };


  networking = {
    hostName = "sanddorn";

    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    firewall.enable = false;
  };

  programs.tmux.enable = true;

  # Do not log to flash:
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  documentation.enable = false;

  system.stateVersion = "21.05";
}
