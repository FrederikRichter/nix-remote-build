{
  description = "Nix remote builder script that builds on remote and copies result to local store";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Use the latest nixpkgs
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux"; # Change this if you're on a different architecture
    pkgs = import nixpkgs { inherit system; };
  in {
    packages.${system}.nix-remote-build = pkgs.stdenv.mkDerivation {
      name = "nix-remote-build";

      # Specify the script as the source
      src = ./.;

      buildInputs = [
        pkgs.openssh 
        pkgs.git        
        pkgs.openssl
        pkgs.bash
      ];

      # Ensure that the script is executable
      installPhase = ''
        mkdir -p $out/bin
        cp ${./nix-remote-build} $out/bin/nix-remote-build
        chmod +x $out/bin/nix-remote-build
      '';
    };

    defaultPackage.${system} = self.packages.${system}.nix-remote-build;
  };
}
