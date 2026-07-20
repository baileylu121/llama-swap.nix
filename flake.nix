{
  description = "llama-swap nix modular service";

  inputs = {
    # temp pin until the bad reload signal PR gets fixed
    nixpkgs.url = "github:imincik/nixpkgs/nixos-unstable+pr-540857";

    nimi = {
      url = "github:weyl-ai/nimi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixified-ai = {
      url = "github:nixified-ai/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs: let

      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      eachSystem =
        fn:
        lib.genAttrs systems (
          system:
          (fn rec {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          })
        );
    in {
      lib.parseLLamaSwapCfg = module:
        let
          evalResult = lib.evalModules {
            modules = [
              ./llama-swap-config.nix
              module
            ];
            class = "llama-swap";
          };
        in
          lib.generators.toYAML evalResult.config;

      packages = eachSystem (
        { pkgs, system, ... }:
        let
          nimi = inputs.nimi.packages.${system}.default;
        in
        {
          default = nimi.mkNimiBin {
            services."llama-example" = {
              imports = [ (lib.modules.importApply ./llama-swap.nix { inherit pkgs; }) ];
            };
          };
        }
      );

      modules = eachSystem (
        { pkgs, system, ... }:
        {
          default = (lib.modules.importApply ./llama-swap.nix { inherit pkgs; });
        }
      );

      devShells = eachSystem (
        { pkgs, system, ... }:
        {
          default = import ./devshell.nix { inherit pkgs; };
        }
      );
    };
}
