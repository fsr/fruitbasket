{ config, lib, ... }:
let
  wireguard_port = 51820;
in
{
  sops.secrets = {
    "wg-fsr" = {
      owner = config.users.users.systemd-network.name;
    };
  };

  networking = {
    # portunus module does weird things to this, so we force it to some sane values
    hosts = {
      "127.0.0.1" = lib.mkForce ["quitte.ifsr.de" "quitte" ];
      "::1" = lib.mkForce ["quitte.ifsr.de" "quitte" ];
    };
    hostId = "a71c81fc";
    domain = "ifsr.de";
    hostName = "quitte";
    rDNS = config.networking.fqdn;
    enableIPv6 = true;
    useDHCP = true;
    interfaces.ens18.useDHCP = true;
    useNetworkd = true;
    nftables.enable = true;

    firewall = {
      allowedUDPPorts = [ wireguard_port ];
      logRefusedConnections = false;
    };
    wireguard.enable = true;
  };

  services.resolved = {
    enable = true;
    #dnssec = "false";
    fallbackDns = [ "1.1.1.1" ];
  };

  # workaround for networkd waiting for shit
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
    "" # clear old command
    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --any"
  ];

  systemd.network = {
    enable = true;

    # Interfaces on the machine
    networks."10-wired-default" = {
      matchConfig.Name = "ens18";

      address = [ "141.30.30.169/25" ];
      routes = [
        {
          routeConfig.Gateway = "141.30.30.129";
        }
      ];
      networkConfig = {
        DNS = "141.30.1.1";
        #IPv6AcceptRA = true;
      };
    };

    # defining network device for wireguard connections
    netdevs."fsr-wg" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "fsr-wg";
        Description = "fsr enterprise wireguard";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."wg-fsr".path;
        ListenPort = wireguard_port;
      };
      wireguardPeers = [
        {
          # tassilo
          wireguardPeerConfig = {
            PublicKey = "vgo3le9xrFsIbbDZsAhQZpIlX+TuWjfEyUcwkoqUl2Y=";
            AllowedIPs = [ "10.66.66.100/32" ];
            PersistentKeepalive = 25;
          };
        }
      ];
    };

    # fsr wireguard server
    networks."fsr-wg" = {
      matchConfig.Name = "fsr-wg";
      networkConfig = {
        Address = "10.66.66.1/24";
        IPForward = "ipv4";
      };
    };
  };
}
