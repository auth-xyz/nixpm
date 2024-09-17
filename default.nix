{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "nixpm";
  version = "1.0.5";
  src = ./.;
  buildInputs = [ pkgs.makeWrapper ];
  buildPhase = ''
    mkdir -p $out/bin
  '';
  installPhase = ''
    install -Dm755 nixpm.sh $out/bin/nixpm
  '';
}

