{
    inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    outputs = { self, nixpkgs }:
        with import nixpkgs { system = "x86_64-linux"; };

        nixpkgs.mkShell {
            buildInputs = [
                pkgs.luajit
                pkgs.shellcheck
                pkgs.luajitPackages.luarocks
                pkgs.luajitPackages.luacov
                pkgs.sumneko-lua-language-server
            ];
        }
}
