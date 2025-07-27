{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gcc
    libgcc
    binutils
    libgccjit
    glibc.dev
  ];
  
  shellHook = ''
    export LIBRARY_PATH=${pkgs.glibc}/lib:${pkgs.libgccjit}/lib:$LIBRARY_PATH
  '';
}
