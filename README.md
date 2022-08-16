# batstat

Track and display statistics about battery usage, like charge cycles and average time between charges.

## Installing

TODO

## Usage

TODO

## Building static binary

### Using nix

1. [Enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes) in nix.
2. Build with:
   ```bash
   ~/repos/batstat $ nix develop .#release -c make
   ```

### Manual (Not recommended)

1. Install the following dependencies using your distro's package manager:
   - make >= 4.3
   - luajit >= 2.1.0
   - luarocks >= 3.9.0
   - musl >= 1.2.3
   - zig >= 0.9.1
   - xz >= 5.2.5
2. Compile a static version of libunwind 1.6.2
3. `make`

## Development

### Setting up the dev environment

#### Spawn a shell with all dev dependencies using nix

1. [Enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes) in nix.
2. Enter the dev shell:
   ```bash
   ~/repos/batstat $ nix develop -c $SHELL
   ```
3. Initialize luarocks:
   ```bash
   ~/repos/batstat $ luarocks init
   ```

To automatically enter the dev shell when entering the repo directory:

1. Install direnv
2. `~/repos/batstat $ echo "use flake" >> .envrc`

#### Manual

1. Install the following dependencies using your distro's package manager:
   - luajit >= 2.1.0
   - luarocks >= 3.9.0
   - lua-language-server >= 3.4.1
2. Initialize luarocks:
   ```bash
   ~/repos/batstat $ luarocks init
   ```

### Building

1. `./luarocks build`

### Running

1. `./lua_modules/bin/batstat`

### Running tests

1. `./luarocks test`

