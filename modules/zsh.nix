{ pkgs, ... }:
{
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
    shellAliases = {
      l = "ls -l";
      ll = "ls -la";
      la = "ls -a";
      less = "bat";
    };
    histSize = 100000;
    histFile = "~/.local/share/zsh/history";
    autosuggestions = {
      enable = true;
      highlightStyle = "fg=#00bbbb,bold";
    };

    shellInit = ''
      zsh-newuser-install () {}
    '';
    interactiveShellInit = ''
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      source ${pkgs.agdsn-zsh-config}/etc/zsh/zshrc
    '';
  };
}

