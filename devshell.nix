{ pkgs, ... }:
pkgs.mkShell {
  packages = [
    pkgs.llama-swap
  ];
}
