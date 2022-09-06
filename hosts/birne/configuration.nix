# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =[ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "birne";
    interfaces.wlp4s0.useDHCP = true;
    interfaces.enp1s0.useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlp4s0" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
   users.users.printer = {
     isNormalUser = true;
     password = "printer";
     extraGroups = [];
   };

  environment.systemPackages = with pkgs; [
    firefox
  ];

  system.stateVersion = "21.05";

}

