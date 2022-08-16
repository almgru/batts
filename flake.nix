{
    inputs = {
        nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
        flake-utils.url = github:numtide/flake-utils;
    };

    outputs = { self, nixpkgs, flake-utils }:
        with flake-utils.lib;

        eachSystem [
            system.x86_64-linux
            system.i686-linux
            system.aarch64-linux
            system.armv7l-linux
        ] (system:
            let pkgs = nixpkgs.legacyPackages.${system};
            in {
                devShells = {
                    default = pkgs.mkShell {
                        packages = [
                            pkgs.luajit
                            pkgs.luajitPackages.luarocks
                            pkgs.sumneko-lua-language-server
                        ];
                    };

                    release = pkgs.mkShell {
                        packages = [
                            pkgs.luajit
                            pkgs.luajitPackages.luarocks
                            pkgs.zig
                            pkgs.pkgsStatic.libunwind
                            pkgs.xz
                        ];
                    };
                };
            }
        );
}
