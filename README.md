# tapppi/nix-config

My system configuration for macOS and nixOS built with Nix.
The goal is to have a single reproducible configuration source for my working
environments.

Nix is a powerful package manager for Linux and Unix systems that ensures
reproducible, declarative, and reliable software management.

## Status

Currently configuring the macOS configuration based on
[my old macos-setup repo](https://github.com/tapppi/macos-setup).
The nixOS setup is wholly untested and simply there as a placeholder.

## Layout

```
.
├── apps         # Nix commands used to bootstrap and build configuration
├── hosts        # Host-specific configuration
├── modules      # macOS and nix-darwin, NixOS, and shared configuration
├── overlays     # Drop an overlay file in this dir, and it runs. So far, mainly patches.
├── templates    # Starter versions of this configuration
```

## Configuration references

This is a listing of the location's of the most important configurations,
referencing the template used where applicable.

- Template for the overall nix config is from the awesome
  [dustinlyons config](https://github.com/dustinlyons/nixos-config/tree/main).
- [neovim configs]()

## Future ideas

- Remote terminal config, i.e. a simpler configuration with minimal
  dependencies, installable on a remote system. Provide most important terminal 
  configurations and programs without system configuration.
