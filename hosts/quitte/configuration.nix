{ pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./network.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  #boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  #boot.kernelParams = [ "video=VGA-1:1024x768@30" ];
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.supportedFilesystems = [ "zfs" ];
  #boot.zfs.devNodes = "/dev/";

  services.qemuGuest.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  # prevent fork bombs
  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "nproc";
      type = "hard";
      value = "2000";
    }
    {
      domain = "@nixbld";
      item = "nproc";
      type = "hard";
      value = "10000";
    }
  ];
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  systemd = {
    services.nix-daemon.serviceConfig = {
      MemoryMax = "32G";
    };
    # all users together may not use more than $MemoryMax of RAM
    slices."user".sliceConfig = {
      MemoryMax = "32G";
    };
  };


  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 443 80 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

