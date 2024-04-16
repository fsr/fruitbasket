{ lib, pkgs, ... }:
{
  users.users.root.shell = pkgs.zsh;
  programs.command-not-found.enable = false;
  programs.nix-index-database.comma.enable = true;
  environment.systemPackages = with pkgs; [
    # fzf
    bat
    duf
  ];
  programs.fzf = {
    keybindings = true;
  };
  programs.zsh = {
    enable = true;
    autosuggestions = {
      enable = true;
      highlightStyle = "fg=#00bbbb,bold";
    };

    # don't override agdsn-zsh-config aliases
    shellAliases = lib.mkForce { };

    shellInit = ''
      zsh-newuser-install () {}
    '';
    interactiveShellInit = ''
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      HW_CONF_ALIASES_GIT_AUTHOR_REMINDER=0
      source ${pkgs.agdsn-zsh-config}/etc/zsh/zshrc
    '';
    promptInit = "";
  };
}

