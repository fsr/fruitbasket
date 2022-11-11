{ config, lib, pkgs, buildVM, ... }:

{
  assertions = [
    { assertion = buildVM; message = "this module may only be used when building a VM!"; }
  ];

  users.users.root.hashedPassword = "";
  users.users.root.initialPassword = "";
  users.mutableUsers = false;

  networking.useDHCP = lib.mkForce false;
  networking.interfaces = lib.mkForce {
    eth0.useDHCP = true;
  };
  networking.defaultGateway = lib.mkForce null;

  sops.defaultSopsFile = lib.mkForce ../secrets/test.yaml;
  sops.age.sshKeyPaths = lib.mkForce [ ];
  sops.gnupg.sshKeyPaths = lib.mkForce [ ];
  sops.age.keyFile = lib.mkForce "${../keys/test.age}";
  sops.age.generateKey = lib.mkForce false;


  # don't use production endpoint for test vm, to avoid rate limiting
  security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

  # Set VM disk size (in MB)
  virtualisation.diskSize = 2048;

  # Set VM ram amount (in MB)
  virtualisation.memorySize = 2048;

  virtualisation.forwardPorts = [
    { from = "host"; host.port = 2222; guest.port = 22; }
  ];
  virtualisation.graphics = false;

  # show systemd logs on console
  services.journald.extraConfig = ''
    ForwardToConsole=yes
  '';
}
