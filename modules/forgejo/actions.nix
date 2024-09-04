{ config, pkgs, ... }:
{
  sops.secrets."forgejo/runner-token" = { };
  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
    instances."quitte" = {
      enable = true;
      labels = [
        # provide a debian base with nodejs for actions
        "debian-latest:docker://node:18-bullseye"
        # fake the ubuntu name, because node provides no ubuntu builds
        "ubuntu-latest:docker://node:18-bullseye"
        # provide native execution on the host
        # "native:host"
      ];
      tokenFile = config.sops.secrets."forgejo/runner-token".path;
      url = "https://git.ifsr.de";
      name = "quitte";
    };
  };
}
