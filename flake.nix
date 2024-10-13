{
  description = "Nix remote builder script that really builds on remote and copies result to local store";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Use the latest nixpkgs
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux"; # Change this if you're on a different architecture
    pkgs = import nixpkgs { inherit system; };
  in {
    packages.${system}.nix-remote-build = pkgs.writeShellScriptBin "nix-remote-build" ''
    #!${pkgs.bash}/bin/bash
      ${./nix-remote-build} "$@"
    '';
    
    defaultPackage.${system} = self.packages.${system}.nix-remote-build;
  };
}
