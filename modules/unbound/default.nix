{ ... }:
{
  services.resolved.settings.Resolve = {
    DNSStubListener = false;
  };
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "127.0.0.1" "::1" ];
      };
    };
  };
}
