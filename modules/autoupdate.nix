{ pkgs, config, ... }:

{
  system.autoUpgrade = {
    enable = true;
    dates = "12:00";
    # might need to move this into the configuration of `birne`?
    allowReboot = true;
  };
}
