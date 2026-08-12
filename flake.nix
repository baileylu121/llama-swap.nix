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
            inherit system lib inputs;
            pkgs = nixpkgs.legacyPackages.${system};
            serviceModule = (lib.modules.importApply ./modules/root.nix { inherit pkgs nixified-ai; });
          })
        );
    in
    {
      packages = eachSystem (
        {
          pkgs,
          system,
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

      checks = eachSystem (
        {
          inputs,
          system,
          ...
        }:
        {
          default = inputs.self.packages.${system}.default;
        }
      );

      modules = eachSystem (
        {
          serviceModule,
          ...
        }:
        {
          default = serviceModule;
          llamaSwap = serviceModule;
        }
      );

      lib = eachSystem (import ./lib.nix);

      formatter = eachSystem ({ pkgs, ... }: pkgs.nixfmt-tree);
    };
}
