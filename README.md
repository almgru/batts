# batts

```bash
$ batts stats
BAT1
mean off-line power draw:                   4.71 W (± 2.83 W)
mean discharge rate per hour:               10.78% (± 8.87%)
mean off-line capacity range:               61% - 39%
mean discharge time:                        2h 35m (± 1h 7m)
extrapolated full charge discharge time:    9h 17m (± 5h 5m)
capacity health:                            97%
cycle count:                                28
```

Simple Linux utility to track and display statistics about battery usage, like average time to discharge, average
power draw and charge cycles used.

Distributed as a static musl binary, so should work on any Linux distribution.

## Installing

### With [stew](https://github.com/marwanhawari/stew)

1. `stew install almgru/batts`.
2. Select latest version.
3. Select tar.xz asset file.

If you install with stew you can easily upgrade with `stew upgrade batts`. However, stew only manages the binary, to
get the service file you still need to extract it from the tarball. It can be found in `~/.local/share/stew/pkg`.

### Manually

1. Download the latest archive from the releases page.
2. Extract the archive and copy the `batts` binary to somewhere in your `$PATH`.

### Starting the daemon

A systemd service file is provided in the release archive. See below for installing it.

If you can't or don't want to use systemd, you can just start the daemon in your `~/.profile`, `~/.bash_profile`,
`~/.zprofile` or `~/.config/fish/config.fish`:

```bash
batts daemon &
```

#### Using systemd user (optional)

1. Copy `service/systemd/batts-daemon.service` from the archive to `~/.config/systemd/user/batts-daemon.service`.
2. Start the service:
   ```bash
   $ systemctl --user enable --now batts-daemon
   ```

#### Using runit (optional)

1. Copy `service/runit/batts` from the archive to `/etc/sv/batts`.
2. Enable the service:
   ```bash
   $ sudo ln -sf /etc/sv/batts /var/service/
   ```

## Usage

To see statistics about battery use, run `batts stats`. Note that some stats will not be available until the daemon
has run for a while.

To start the daemon, run `batts daemon`. Note that the daemon runs in the foreground as it's intended to be started
by a service supervisor or in your `~/.profile` equivalent.

### Global options

- __`-l <dir>`__ or __`--log-directory <dir>`__: directory to save battery log file to. Defaults to
`~/.local/share/batts`.

### `daemon` options

- __`-i <num>`__ or __`--interval-in-seconds <num>`__: number of seconds to wait before each log entry. Default to `60`.

## Development

### Setting up the dev environment

#### Spawn a shell with all dev dependencies using nix

1. [Enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes) in nix.
2. Enter the dev shell:
   ```bash
   ~/repos/batts $ nix develop -c $SHELL
   ```
3. Initialize luarocks:
   ```bash
   ~/repos/batts $ luarocks init
   ```

To automatically enter the dev shell when entering the repo directory:

1. Install direnv
2. `~/repos/batts $ echo "use flake" >> .envrc`

__NOTE:__ There are two dev shells availabe. The default dev shell described here, and one shell for building the
static binary release. If you need to debug the build of the static binary, use that one instead.

#### Manual

1. Install the following dependencies using your distro's package manager:
   - luajit >= 2.1.0
   - luarocks >= 3.9.0
   - lua-language-server >= 3.4.1
2. Initialize luarocks:
   ```bash
   ~/repos/batts $ luarocks init
   ```

### Building

1. `./luarocks build`

### Running

1. `./lua_modules/bin/batts`

### Running tests

1. `./luarocks test`

### Building static binary

#### Using nix

1. [Enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes) in nix.
2. Build with
   ```bash
   ~/repos/batts $ nix develop '.#release' -c make
   ```

## Credit

See [LICENSE.txt](LICENSE.txt) for credits for dependencies included in binary.

The following software is used during development, testing or building:

- [LuaRocks (v. 3.9.0)](https://luarocks.org/)
- [Nix (v. 2.10.3)](https://nixos.org/)
- [zig (v. 0.9.1)](https://ziglang.org/)
- [luastatic (v. 0.0.12)](https://github.com/ers35/luastatic)
- [busted (v. 2.1.1)](https://lunarmodules.github.io/busted/)
- [luaposix (v. 35.1)](https://github.com/luaposix/luaposix)
- [lua-language-server (v. 3.4.1)](https://github.com/sumneko/lua-language-server)
- [GNU Make (v. 4.3)](https://www.gnu.org/software/make/)
- [xz (v. 5.2.5)](https://tukaani.org/xz/)
- [GNU coreutils (v. 9.1)](https://www.gnu.org/software/coreutils/)
- [GNU findutils (v. 4.9.0)](https://www.gnu.org/software/findutils/)
- [UnZip (v. 6.00)](http://infozip.sourceforge.net/)

