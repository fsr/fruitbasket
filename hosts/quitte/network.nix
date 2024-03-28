{ config, lib, ... }:
let
  wireguard_port = 51820;
in
{
  networking = {
    # portunus module does weird things to this, so we force it to some sane values
    hosts = {
      "127.0.0.1" = lib.mkForce [ "quitte.ifsr.de" "quitte" ];
      "::1" = lib.mkForce [ "quitte.ifsr.de" "quitte" ];
    };
    hostId = "a71c81fc";
    domain = "ifsr.de";
    hostName = "quitte";
    rDNS = config.networking.fqdn;
    useNetworkd = true;
    nftables.enable = true;

    firewall = {
      allowedUDPPorts = [ wireguard_port ];
      logRefusedConnections = false;
    };
  };

  services.resolved = {
    enable = true;
    fallbackDns = [ "9.9.9.9" ];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;

    # Interfaces on the machine
    networks."10-wired-default" = {
      matchConfig.Name = "enp65s0f0np0";

      address = [ "141.30.30.169/25" ];
      routes = [
        {
          routeConfig.Gateway = "141.30.30.129";
        }
      ];
      networkConfig = {
        DNS = "141.30.1.1";
      };
    };
  };
}
