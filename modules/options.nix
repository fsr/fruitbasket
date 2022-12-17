{ config, lib, ... }: with lib; {
  options.fsr = {
    enable_office_bloat = mkOption {
      type = types.bool;
      default = false;
      description = "install heavy office bloat like texlive, okular, ...";
    };
    domain = mkOption {
      type = types.str;
      default = "ifsr.de";
      description = "under which top level domain the services should run";
    };
  };
}
