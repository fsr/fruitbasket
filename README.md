# Infrastructure configuration for FSR-operated machines

This repository contains the NixOS configuration files for FSR machines.


## Machines configures by this repository:
- `birne` (the printer notebook)
- `tomate` (backup endpoint and office computer)
- `quitte` (new server predestined to run all important services)

## Setup

Clone this repository on the target machine to `/etc/nixos` and build the desired host configuration e.g.

```bash
# you may need to copy the generated hardware-configuration.nix to hosts/<hostname>/hardware-configuraion.nix
nixos-rebuild switch --flake .#<hostname>
```

## Tips and Tricks
<details>
  <summary>Resolving merge conflicts in sops files</summary>
  
  ### Required steps
  1. Manually resolve the conflicts in the encrypted file
  2. Open the file using `sops --ignore-mac secrets/<hostname>.yml`
  3. Change one letter in one of the yml entries to let sops know it has to regenerate the MAC
  4. Close the file. Open it again and revert the change you just did in step 3.
</details>
