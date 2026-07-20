{ pkgs, ... }:
{ lib, config, ... }:
let
  inherit (lib) mkOption mkPackageOption types;

  cfg = config.llama-swap;
in
{
  _class = "service";

  options.llama-swap = {
    package = mkPackageOption pkgs "llama-swap" { };
  };

  config =
    let
      wrapper = pkgs.writeShellApplication {
        name = "llama-swap";
        text = ''
          ${lib.getExe cfg.package} \
            "$@"
        '';
      };
    in
    {
      process.argv = [ (lib.getExe wrapper) ];
    };
}
