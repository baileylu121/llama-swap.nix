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
    { nixpkgs, nixified-ai, ... }@inputs: let

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
    in {
      packages = eachSystem (
        { pkgs, system, serviceModule, ... }:
        let
          nimi = inputs.nimi.packages.${system}.default;
          llama-swap-lib = inputs.self.lib.${system};
        in
        {
          default = nimi.mkNimiBin {
            services."llama-example" = {
              imports = [ serviceModule ];

              config.llama-swap.config = let
                qwen = llama-swap-lib.fetchHuggingFace {
                  url = "https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-BF16.gguf";
                  name = "Qwen3.5-0.8B";
                  sha256 = lib.fakeHash;
                  passthru = { };
                };
              in llama-swap-lib.writeLLamaSwapCfgFile {
                models.qwen = {
                  cmd = ''
                    ${lib.getExe pkgs.llama-cpp}
                    --model ${qwen}
                  '';
                  name = "Qwen3.5-0.8B";
                };
              };
            };
          };
        }
      );

      modules = eachSystem (
        { pkgs, system, serviceModule, ... }:
        {
          default = serviceModule;
        }
      );

      lib = eachSystem (
        { pkgs, ... }:
        rec {
          writeLLamaSwapCfgFile = module:
          let
            evalResult = lib.evalModules {
              modules = [
                ./llama-swap-config.nix
                module
              ];
              class = "llama-swap";
            };
          in
          pkgs.writers.writeYAML "llama-swap-config.yaml" evalResult.config;

          fetchHuggingFace = pkgs.callPackage "${nixified-ai}/flake-modules/fetchers/fetchresource/default.nix" {};
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
