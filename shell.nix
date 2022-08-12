{ sources ? import ./nix/sources.nix,
pkgs ? import sources.nixpkgs {}
}:

pkgs.mkShell {
    buildInputs = [
        pkgs.luajit
        pkgs.shellcheck
        pkgs.luajitPackages.luarocks
        pkgs.sumneko-lua-language-server
    ];
}
