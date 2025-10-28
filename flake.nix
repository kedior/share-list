{
  description = "bun & gleam env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ bashInteractive bun gleam ];
          shellHook = ''
            export SHELL=${pkgs.bashInteractive}/bin/bash
            export PS1="(nix-dev) $PS1"
            echo "Bun version: $(bun --version)"
            echo "Gleam version: $(gleam --version)"
            bun install
            gleam deps download
          '';
        };
      });
}

