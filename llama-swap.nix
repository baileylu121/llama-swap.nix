{ pkgs, nixified-ai, ... }:
{ lib, config, ... }:
let
  inherit (lib) mkOption mkPackageOption types;

  cfg = config.llama-swap;
in
{
  _class = "service";

  options.llama-swap = {
    package = mkPackageOption pkgs "llama-swap" { };
    config = mkOption {
      description = ''
        Path to config file
      '';
      type = types.pathInStore;
    };
    listen = mkOption {
      description = ''
        Port to listen on
      '';
      type = types.port;
      default = 8080;
    };
    tlsCertFile = mkOption {
      description = ''
        TLS certificate file path
      '';
      type = types.nullOr types.pathInStore;
      default = null;
    };
    tlsKeyFile = mkOption {
      description = ''
        TLS key file path
      '';
      type = types.nullOr types.pathInStore;
      default = null;
    };
  };

  config =
    let
      wrapper = pkgs.writeShellApplication {
        name = "llama-swap";
        text = ''
          ${lib.getExe cfg.package} \
          -config ${cfg.config} \
          -listen ${toString cfg.listen} \
          ${lib.optionalString (cfg.tlsCertFile != null) "-tls-cert-file ${cfg.tlsCertFile}"} \
          ${lib.optionalString (cfg.tlsKeyFile != null) "-tls-key-file ${cfg.tlsKeyFile}"} \
          "$@"
        '';
      };
    in
    {
      process.argv = [ (lib.getExe wrapper) ];
    };
}
