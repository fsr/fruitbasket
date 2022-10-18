{ config, ... }:

{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.wg-quick.interfaces = {
    wg-dvb = {
      # pubkey: 8iQQSCI14dObcrMw0/rZJxfvpOAhy3CU+haJq2nyIzc=
      address = [ "10.13.37.1/32" ];
      privateKeyFile = config.sops.secrets.wg-seckey.path;
      listenPort = 51820;
      peers = [
        {
          # Tassilo
          publicKey = "vgo3le9xrFsIbbDZsAhQZpIlX+TuWjfEyUcwkoqUl2Y=";
          allowedIPs = [ "10.13.37.2/32" ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}


