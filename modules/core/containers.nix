{ pkgs, ... }:
{
  virtualisation.containers.enable = true;
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        firewall-backend= "nftables";
      };
    };
    # podman = {
    #   enable = true;

    #   # Create a `docker` alias for podman, to use it as a drop-in replacement
    #   dockerCompat = true;

    #   # Required for containers under podman-compose to be able to talk to each other.
    #   defaultNetwork.settings.dns_enabled = true;
    # };
  };
  virtualisation.oci-containers.backend = "docker";
  systemd.services.docker.path = [ pkgs.nftables ];


  # Useful otherdevelopment tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    # podman-tui # status of containers in the terminal
    #docker-compose # start group of containers for dev
    #podman-compose # start group of containers for dev
  ];
}
