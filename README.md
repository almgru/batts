# batstat

Simple Linux utility to track and display statistics about battery usage, like average time to discharge, average
power draw or charge cycles used.

Distributed as a static musl binary, so should work on any x86\_64 Linux distribution.

## Installing

1. Download the latest archive from the releases page.
2. Extract the archive and copy the `batstat` binary to somewhere in your `$PATH`.

### Starting the daemon

A systemd service file is provided in the release archive. See below for installing it.

If you can't or don't want to use systemd, you can just start the daemon in your `~/.profile`, `~/.bash_profile`,
`~/.zprofile` or `.config/fish/config.fish`:

```bash
batstat daemon &
```

#### Using systemd user (optional)

1. Copy `service/systemd/batstat-daemon.service` from the archive to `~/.config/systemd/user/batstat-daemon.service`.
2. Start the service:
   ```bash
   $ systemctl --user enable --now batstat-daemon
   ```

## Usage

To see statistics about battery use, run `batstat stats`. Note that some stats will not be available until the daemon
has run for a while.

To start the daemon, run `batstat daemon`. Note that the daemon runs in the foreground as it's intended to be started
by a service supervisor or in your `~/.profile` equivalent.

### Global options

- __`-l <dir>`__ or __`--log-directory <dir>`__: directory to save battery log file to. Defaults to
`~/.local/share/batstat`.

### `daemon` options

- __`-i <num>`__ or __`--interval-in-seconds <num>`__: number of seconds to wait before each log entry. Default to `60`.

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

__NOTE:__ There are two dev shells availabe. The default dev shell described here, and one shell for building the
static binary release. If you need to debug the build of the static binary, use that one instead.

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

### Building static binary

#### Using nix

1. [Enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes) in nix.
2. Build with
   ```bash
   ~/repos/batstat $ nix develop '.#release' -c make
   ```

#### Manual (Not recommended)

1. Install the following dependencies using your distro's package manager:
   - make >= 4.3
   - luajit >= 2.1.0
   - luarocks >= 3.9.0
   - musl >= 1.2.3
   - zig >= 0.9.1
   - xz >= 5.2.5
2. Compile a static version of libunwind 1.6.2
3. Build:
   ```bash
   ~/repos/batstat $ make
   ```

### Compiling for other platforms

\*Currently only supports aarch64.

1. Install `qemu-system-aarch64`.
2. Enable [qemu-user-static](https://github.com/multiarch/qemu-user-static):

   With docker: `docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`
   
   With podman: `sudo podman run --rm --privileged multiarch/qemu-user-static --reset -p yes`
3. Add the following to `/etc/nix/nix.conf`:
   ```
   extra-platforms = aarch64-linux
   extra-sandbox-paths = /usr/bin/qemu-system-aarch64
   ```
4. Restart the nix daemon. For example with systemd: `sudo systemctl restart nix-daemon`
5. To compile for aarch64, run:
```bash
~/repos/batstat $ nix develop '.#devShells.aarch64-linux.release' -c make TARGET=aarch64-linux
```

