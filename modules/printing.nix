{ pkgs, config, ... }:

{
  # Enable CUPS to print documents.
  services = {
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
      deviceUri = "dnssd://Kyocera%20ECOSYS%20M6630cidn._ipp._tcp.local/?uuid=4509a320-007e-002c-00dd-002507504ad0";
      location = "FSR Buero";
      model = "Kyocera ECOSYS M6630cidn KPDL";
      name = "Heiko";
    }
    {
      description = "Drucker im FSR Buero";
      deviceUri = "dnssd://Kyocera%20ECOSYS%20M6630cidn._pdl-datastream._tcp.local/?uuid=4509a320-007e-002c-00dd-002507504ad0";
      location = "FSR Buero";
      model = "Kyocera ECOSYS M6630cidn KPDL";
      name = "Heiko";
    }
  ];
}
