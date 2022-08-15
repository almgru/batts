# batstat

Track and display statistics about battery usage, like charge cycles and average time between charges.

## Building static binary

### Using nix

```bash
~/repos/batstat $ nix develop .#release -c make
```

### Manual

TODO

## Setting up dev environment

### Spawn a shell with all dev dependencies using nix

```bash
~/repos/batstat $ nix develop -c $SHELL
~/repos/batstat $ luarocks init
```

### Manual

TODO

