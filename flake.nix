{
  description = "A flake for nixpm, a script to manage system and user packages in NixOS";

  # Declare inputs, primarily nixpkgs here
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Define the outputs, which include packages, apps, etc.
  outputs = { self, nixpkgs }: {
    # Define the packages for the x86_64-linux platform
    packages.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      nixpm = pkgs.stdenv.mkDerivation {
        pname = "nixpm";  # Name of the package
        version = "1.0.1";  # Version of the package

        # Source directory (current directory where flake.nix is located)
        src = ./.;

        # Add necessary build dependencies
        buildInputs = [ pkgs.makeWrapper ];

        # Define the build phase (create the output directory)
        buildPhase = ''
          mkdir -p $out/bin
        '';

        # Install the script as an executable in the bin directory
        installPhase = ''
          install -Dm755 nixpm.sh $out/bin/nixpm
        '';
      };
    };

    # Define the default package to be built
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.nixpm;

    # Define the default app, making it executable directly from the flake
    defaultApp.x86_64-linux = {
      type = "app";
      program = "${self.packages.x86_64-linux.nixpm}/bin/nixpm";
    };
  };
}

