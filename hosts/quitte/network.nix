{ config, lib, ... }:
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

      address = [

        "141.30.30.194/26"
        "2a13:dd85:b23:1::1337/64"
      ];
      routes = [
        {
          Gateway = "141.30.30.193";
        }
        {
          Gateway = "fe80::7a24:59ff:fe5e:6e2f";
        }
      ];
      networkConfig = {
        DNS = "141.30.1.1";
        LLDP = true;
        EmitLLDP = "nearest-bridge";
      };
    };
  };
}
