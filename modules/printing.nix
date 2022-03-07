{ pkgs, config, ... }:

{
  # Enable CUPS to print documents.
  services= {
    printing.enable = true;
    printing.drivers = with pkgs; [
      gutenprint
      gutenprintBin
      hplip
      hplipWithPlugin
    ];
    avahi.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnome.gnome-control-center
  ];
  # set up Heiko
  hardware.printers.ensurePrinters = [
     {
       description = "Drucker im FSR Buero";
       deviceUri = "";
       location = "FSR Buero";
       model = "Kyocera ECOSYS M6630cidn KPDL";
       name = "Heiko";
     }
  ];
}
