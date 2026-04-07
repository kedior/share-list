{
  description = "bun & gleam env";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem = f:
        nixpkgs.lib.genAttrs supportedSystems (system:
          f {
            pkgs = import nixpkgs { inherit system; };
          });
    in {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            bashInteractive
            bun
            gleam
          ];
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
    } ;
}
