{ config, ... }:
{
  sops.secrets.ifsr-apb-auth = { };
  networking = {
    domain = "ifsr.de";
    hostName = "tomate";
    useNetworkd = true;
    nftables.enable = true;
    # Radius authentification
    supplicant."enp3s0" = {
      driver = "wired";
      configFile.path = config.sops.secrets.ifsr-apb-auth.path;
    };
  };

  services.resolved = {
    enable = true;
    fallbackDns = [ "9.9.9.9" ];
  };

  systemd.network = {
    enable = true;

    networks."10-wired-default" = {
      matchConfig.Name = "enp3s0";

      address = [ "141.30.86.196/26" ];
      routes = [
        {
          routeConfig.Gateway = "141.30.86.193";
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
