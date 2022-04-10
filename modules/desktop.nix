{ pkgs, config, ... }:

{
  # enable XFCE as lightweight desktop environment
  services = {
  	xserver.enable = true;
	xserver.desktopManager.xfce.enable = true;
  	xserver.displayManager.defaultSession = "xfce";

  	# Configure keymap in X11
  	xserver.layout = "de";
  	xserver.xkbOptions = "eurosign:e,ctrl:nocaps,compose:prsc";

  	# enable touchpad support
  	xserver.libinput.enable = true;
  };
  # enable sound
  sound.enable = true;
  sound.mediaKeys.enable = true;
  hardware.pulseaudio.enable = true;

  # additional programs for a lightweight working office environment
  environment.systemPackages = with pkgs; [
    ## audio management
    pavucontrol
    ## terminal, browsers, text editing
    vscodium
    firefox
    ## document viewers
    okular
    ## LaTeX
    texlive.combined.scheme-full
    texstudio
    ## the eternal pain continues
    libreoffice-fresh
    # media viewers
    vlc
  ];
}
