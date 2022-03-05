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
  # set up Heiko
  #hardware.printers.ensurePrinters = [
  #   {
  #     description = "Drucker im FSR Buero";
  #     deviceUri = "";
  #     location = "FSR Buero";
  #     model = "";
  #     name = "Heiko";
  #   }
  #];
}
