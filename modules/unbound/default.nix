{ ... }:
{
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "127.0.0.1" ];
        access-control = [ "127.0.0.1 allow" ];
      };
      stub-zone = [
        {
          name = ".";
        }
      ];
    };
  };
}
