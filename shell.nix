{ sources ? import ./nix/sources.nix,
pkgs ? import sources.nixpkgs {}
}:

pkgs.mkShell {
    buildInputs = [
        pkgs.luajit
        pkgs.shellcheck
        pkgs.luajitPackages.luarocks
        pkgs.luajitPackages.luacov
        pkgs.sumneko-lua-language-server
    ];
}
