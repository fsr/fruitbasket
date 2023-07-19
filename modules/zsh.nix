{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # fzf
    bat
    duf
  ];
  users.defaultUserShell = pkgs.zsh;
  programs.fzf = {
    fuzzyCompletion = true;
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

    shellInit =
      ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        zsh-newuser-install () {}
      '';
  };
}

