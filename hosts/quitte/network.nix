{ config, lib, ... }:
{
  sops.secrets."wg-ese" = {
    owner = config.users.users.systemd-network.name;
  };
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
      allowedUDPPorts = [ 10000 ];
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
        LLDP = true;
        EmitLLDP = "nearest-bridge";
      };
    };
    netdevs."30-wireguard-ese" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."wg-ese".path;
        ListenPort = 10000;
        RouteTable = "main";
        RouteMetric = 30;
      };
      wireguardPeers = [

        {
          wireguardPeerConfig = {

            PublicKey = "gTWcZ8dAb735kY0vs/LwnBdap5J6+eeHAsLXCu+C52M=";
            AllowedIPs = "10.20.24.2/24";
          };
        }
      ];
    };
    networks."30-wireguard-ese" = {
      matchConfig.Name = "wg0";
      address = [ "10.20.24.1/24" ];
      # networkConfig = {
      #   DNSSEC = false;
      #   BindCarrier = [ "ens3" ];
      # };
    };
  };
}
