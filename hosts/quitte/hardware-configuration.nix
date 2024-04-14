{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "megaraid_sas" "xhci_pci" "nvme" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "rpool/nixos/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/nixos/home";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "rpool/nixos/nixnew";
    fsType = "zfs";
  };

  fileSystems."/var/lib" = {
    device = "rpool/nixos/var/lib";
    fsType = "zfs";
  };

  fileSystems."/var/log" = {
    device = "rpool/nixos/var/log";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3278-8D00";
    fsType = "vfat";
    options = [ "nofail" ];
  };
  fileSystems."/boot2" = {
    device = "/dev/disk/by-uuid/3366-F71E";
    fsType = "vfat";
    options = [ "nofail" ];
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
