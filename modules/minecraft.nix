{...}:
{
  systemd.nspawn.minecraft = {
    enable = true;
    networkConfig = {
      Private = false;
    };
  };
  networking.firewall = {
    # put all ports needed for minecraft here
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };
}
