{ pkgs, config, ... }: {
  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    #font = "Lat2-Terminus16";
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    keyMap = pkgs.lib.mkForce "uk";
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # set root ssh keys
  users.users.root.openssh.authorizedKeys = {
    keys = [
      # RSA keys go into keyFiles because they're shamefully long
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS8xkNH7JvKblekx5oel4HVKCz3uBbQYEaR9Z9nzTAr manuel@ifsr.de"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINogGKyXieCXQvVTa1z3ArS1TlqcVl2sSqvMpOjQo/Um jakob@krbs.me"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjNYNRBsY/Dc+/XOaGDui9tRa4VGPsHwYo3irGnMRbR felix@tycho"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDdOcXORg+akeN2t3yZlKWdoTURKxtV29eQ7UrIMkCHv felix@entropy"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH73n+ZfJqNzIh9rPh6JYQaI4OAw9WKkPeqj2XRFmRfQ pascal@ifsr.de"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmb1kv+7HU1QKE53+gNxUhrggbwomC40Xjxd9hACkoo bennofs@d-cube"
    ];
    keyFiles = [
      ./keys/marcus-sapphire
      ./keys/schrader
      ./keys/jannusch
      ./keys/jannusch-arch
      ./keys/tassilo
      ./keys/jonasga
    ];
  };

  time.timeZone = "Europe/Berlin";

  # basic shell & editor
  programs.vim.defaultEditor = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    atop
    bat
    git
    htop
    fd
    ripgrep
    tldr
    tmux
    usbutils
    wget
    neovim
    nmap
    tcpdump
    bat
	dig
	ethtool
	iftop
ipcalc
iperf3
ipv6calc
lsof
ltrace
strace
mtr
traceroute
smartmontools
sysstat
tree
whois
	exa
	zsh	
  ];
}

