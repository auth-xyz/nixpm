{
  description = "A flake for nixpm and nshpm, scripts to manage system/user packages and Nix shell packages.";

  # Declare inputs, primarily nixpkgs here
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Define the outputs, which include packages, apps, etc.
  outputs = { self, nixpkgs }: {
    # Define the packages for the x86_64-linux platform
    packages.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      # Package for nixpm
      nixpm = pkgs.stdenv.mkDerivation {
        pname = "nixpm";  # Name of the package
        version = "1.0.6";  # Version of the package

        src = ./.;

        buildInputs = [ pkgs.makeWrapper ];

        buildPhase = ''
          mkdir -p $out/bin
        '';

        installPhase = ''
          install -Dm755 nixpm.sh $out/bin/nixpm
        '';
      };

      # Package for nshpm
      nshpm = pkgs.stdenv.mkDerivation {
        pname = "nshpm";  # Name of the package
        version = "1.0.6";  # Version of the package

        src = ./.;

        buildInputs = [ pkgs.makeWrapper ];

        buildPhase = ''
          mkdir -p $out/bin
        '';

        installPhase = ''
          install -Dm755 nshpm.sh $out/bin/nshpm
        '';
      };
    };

    # Define the default package to be built (can be either or both)
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.nixpm;

    # Define both apps, making them executable directly from the flake
    apps.x86_64-linux = {
      nixpm = {
        type = "app";
        program = "${self.packages.x86_64-linux.nixpm}/bin/nixpm";
      };
      nshpm = {
        type = "app";
        program = "${self.packages.x86_64-linux.nshpm}/bin/nshpm";
      };
    };
  };
}

