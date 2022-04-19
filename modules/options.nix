{config, lib, ...}: with lib; {
  options.fsr.enable_office_bloat = mkOption {
    type = types.bool;
    default = false;
    description = "install heavy office bloat like texlive, okular, ...";
  };
}
