{
    inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

    outputs = { self, nixpkgs }:
        let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
        in {
            devShell.${system} = pkgs.mkShell {
                buildInputs = [
                    pkgs.luajit
                    pkgs.luajitPackages.luarocks
                    pkgs.musl
                    pkgs.zig
                    pkgs.pkgsStatic.libunwind
                    pkgs.xz
                    pkgs.shellcheck
                    pkgs.sumneko-lua-language-server
                ];
            };
        };
}
