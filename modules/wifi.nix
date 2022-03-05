#
# Author: Tassilo Tanneberger <tassilo.tanneberger@tu-dresden.de>
# Project: Dotfiles
#
#
# Useful config 
# https://tu-dresden.de/zih/dienste/service-katalog/arbeitsumgebung/zugang_datennetz/wlan-eduroam
# https://www.stura.htw-dresden.de/stura/ref/hopo/dk/nachrichten/eduroam-meets-nixos
#
{ pkgs, config, ... }: {
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


