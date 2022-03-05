# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../modules/base.nix
      ../../modules/autoupdate.nix
      ../../modules/desktop.nix
      ../../modules/printing.nix
      ../../modules/wifi.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Europe/Busingen";
  
  networking = {
    hostName = "birne";
    interfaces.wlp4s0.useDHCP = true;
    networking.interfaces.enp1s0.useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlp4s0" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };  

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;


   users.users.printer = {
     isNormalUser = true;
     password = "printer";
     extraGroups = [];
   };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    firefox
  ];

  system.stateVersion = "21.11";

}

