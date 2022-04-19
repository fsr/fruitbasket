{ pkgs, lib, config, ...}:
let
  fsr-infoscreen = pkgs.fsr-infoscreen;

in {

  systemd = {
    services."fsr-infoscreen" = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.python39}/bin/python39 ${fsr-infoscreen}/build/middleware/infoscreen.py
      '';

      serviceConfig = {
          User = "infoscreen";
          Restart = "on-failure";
        };
      };
    };

    users.users.infoscreen = {
      name = "infoscreen";
      description = "custom user for service infoscreen service";
      isNormalUser = true;
    };

}
