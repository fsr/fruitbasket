#
# Useful config 
# https://tu-dresden.de/zih/dienste/service-katalog/arbeitsumgebung/zugang_datennetz/wlan-eduroam
# https://www.stura.htw-dresden.de/stura/ref/hopo/dk/nachrichten/eduroam-meets-nixos
#
{ pkgs, config, ... }: 
let  
  password = "$(${pkgs.coreutils}/bin/cat /run/secrets/fsr_wifi_psk)";
in {
  networking = {
    wireless = {
      enable = true;
      networks = {
        "FSR" = {
          priority = 10;
          pskRaw = "9dbdf08e1205b1167a812a35cfac4b49a86e155eec707bd47f4d06d829e7d168";
        };
      };
    };
  };
}


