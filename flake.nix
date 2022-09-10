{
    inputs = {
        nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
        flake-utils.url = github:numtide/flake-utils;
    };

    outputs = { self, nixpkgs, flake-utils }:
        with flake-utils.lib;

        eachSystem [
            system.x86_64-linux
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
                            pkgs.autoconf
                            pkgs.automake
                            pkgs.libtool
                            pkgs.xz
                        ];
                    };
                };
            }
        );
}
