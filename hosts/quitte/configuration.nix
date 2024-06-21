{ pkgs, config, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./network.nix
    ];

  boot.loader.systemd-boot = {
    enable = true;
    extraInstallCommands = ''
      ${pkgs.coreutils}/bin/cp -r /boot/* /boot2
    '';
  };
  # boot.kernelParams = [ "video=VGA-1:1024x768@30" ];
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

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

  systemd = {
    services.nix-daemon.serviceConfig = {
      MemoryMax = "32G";
    };
    # all users together may not use more than $MemoryMax of RAM
    slices."user".sliceConfig = {
      MemoryMax = "32G";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

