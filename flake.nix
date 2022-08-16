{
    inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

    outputs = { self, nixpkgs }:
        let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
        in {
            devShells.${system} = {
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
        };
}
