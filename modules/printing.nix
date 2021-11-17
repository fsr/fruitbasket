{ pkgs, config, ... }:

{
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # services.printing.drivers = [
  #   pkgs.gutenprint
  # ];

  # set up Heiko
  # hardware.printers.ensurePrinters = [
  #   {
  #     description = "Drucker im FSR Buero";
  #     deviceUri = "";
  #     location = "FSR Buero";
  #     model = "";
  #     name = "Heiko";
  #   }
  # ];
}
