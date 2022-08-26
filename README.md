# batstat

```bash
$ batstat stats
BAT1
cycle count: 27
capacity health: 97%
mean discharge time: 2h 35m (± 1h 7m)
mean discharge rate per hour: -10.78% (± 8.87%)
extrapolated full charge discharge time: 9h 17m (± 5h 5m)
mean off-line capacity range: 61% - 39%
mean off-line power draw: 4.71 W (± 2.83 W)
```

Simple Linux utility to track and display statistics about battery usage, like average time to discharge, average
power draw and charge cycles used.

Distributed as a static musl binary, so should work on any Linux distribution.

## Installing

### With [stew](https://github.com/marwanhawari/stew)

1. `stew install almgru/batstat`.
2. Select latest version.
3. Select tar.xz asset file.

If you install with stew you can easily upgrade with `stew upgrade batstat`. However, stew only manages the binary, to
get the service file you still need to extract it from the tarball. It can be found in `~/.local/share/stew/pkg`.

### Manually

1. Download the latest archive from the releases page.
2. Extract the archive and copy the `batstat` binary to somewhere in your `$PATH`.

### Starting the daemon

A systemd service file is provided in the release archive. See below for installing it.

If you can't or don't want to use systemd, you can just start the daemon in your `~/.profile`, `~/.bash_profile`,
`~/.zprofile` or `~/.config/fish/config.fish`:

```bash
batstat daemon &
```

#### Using systemd user (optional)

1. Copy `service/systemd/batstat-daemon.service` from the archive to `~/.config/systemd/user/batstat-daemon.service`.
2. Start the service:
   ```bash
   $ systemctl --user enable --now batstat-daemon
   ```

#### Using runit (optional)

1. Copy `service/runit/batstat` from the archive to `/etc/sv/batstat`.
2. Enable the service:
   ```bash
   $ sudo ln -sf /etc/sv/batstat /var/service/
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

