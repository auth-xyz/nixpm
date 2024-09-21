{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "nixpm";
  version = "1.0.6";
  src = ./.;
  buildInputs = [ pkgs.makeWrapper ];
  buildPhase = ''
    mkdir -p $out/bin
  '';
  installPhase = ''
    install -Dm755 nixpm.sh $out/bin/nixpm
    install -Dm755 nshpm.sh $out/bin/nshpm
  '';
}

