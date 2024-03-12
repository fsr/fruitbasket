{ lib, ... }: with lib; {
  options.networking.rDNS = mkOption {
    type = types.str;
    default = networking.fqdn;
    description = "The reverse dns record known to be set for this host.";
  };
}
