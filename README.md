# Infrastructure configuration for FSR-operated machines

This repository contains the NixOS configuration files for FSR machines.


## Machines configures by this repository:
- `birne` (the printer notebook)
- `tomate` (backup endpoint and office computer)

## Setup

Clone this repository on the target machine to `/var/src` and link the folder for the respective machine to the nixos configuration path, e.g.

```bash
# you may need to delete the newly generated config, but make sure to update
# the `hardware-configuration.nix` file if necessary
# rm -rf /etc/nixos
ln -s /var/src/fruitbasket/birne /etc/nixos
```

