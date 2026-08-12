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
    { nixpkgs, nixified-ai, ... }@inputs:
    let

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
            serviceModule = (lib.modules.importApply ./llama-swap.nix { inherit pkgs nixified-ai; });
          })
        );
    in
    {
      packages = eachSystem (
        {
          pkgs,
          system,
          serviceModule,
          ...
        }:
        let
          nimi = inputs.nimi.packages.${system}.default;
        in
        {
          default = nimi.mkNimiBin {
            _module.args.llama-swap-lib = inputs.self.lib.${system};
            imports = [ ./examples/simple-qwen.nix ];
          };
        }
      );

      modules = eachSystem (
        {
          pkgs,
          system,
          serviceModule,
          ...
        }:
        {
          default = serviceModule;
        }
      );

      lib = eachSystem (
        { pkgs, serviceModule, ... }:
        rec {
          writeLLamaSwapCfgFile =
            module:
            let
              evalResult = lib.evalModules {
                modules = [
                  ./llama-swap-config.nix
                  module
                ];
                class = "llama-swap";
                specialArgs = { inherit pkgs; };
              };
            in
            pkgs.writers.writeYAML "llama-swap-config.yaml" evalResult.config;

          fetchHuggingFace =
            args:
            let
              upstream = pkgs.callPackage "${nixified-ai}/flake-modules/fetchers/fetchresource/default.nix" { };
              argsWithPassthru = if args ? passthru then args else args // { passthru = { }; };
            in
            upstream argsWithPassthru;

          module = serviceModule;
        }
      );

      devShells = eachSystem (
        { pkgs, system, ... }:
        {
          default = import ./devshell.nix { inherit pkgs; };
        }
      );

      formatter = eachSystem ({ pkgs, ... }: pkgs.nixfmt-tree);
    };
}
