{
  inputs,
  pkgs,
  serviceModule,
  lib,
  ...
}:
rec {
  /**
    Evaluate a nix options tree representing `llama-swap`'s
    [config.yaml](https://github.com/mostlygeek/llama-swap/blob/main/config.example.yaml),
    and produce a derivation for the generated file.

    # Example

    ```nix
    writeLLamaSwapCfgFile {
      models."my-model" = {
        cmd = ''
          ${lib.getExe' pkgs.llama-cpp "llama-server"} \
          --model ${my-model-src} \
          --port 8080
        '';
        proxy = "http://localhost:8080";
      };
    }
    ```

    # Type

    ```
    writeLLamaSwapCfgFile :: AttrSet -> Derivation
    ```

    # Arguments

    module
    : A nix module tree matching `llama-swap`'s config file'.
  */
  writeLLamaSwapCfgFile =
    module:
    let
      evalResult = lib.evalModules {
        modules = [
          ./modules/config-file.nix
          module
        ];
        class = "llama-swap";
        specialArgs = { inherit pkgs; };
      };
    in
    pkgs.writers.writeYAML "llama-swap-config.yaml" evalResult.config;

  /**
    A re-export of `nixified-ai`'s fetchResource, a variant of
    `fetchurl` that allows one to use their `HF_TOKEN` from
    the local environment to avoid being rate limited.

    This version also allows you to elide `passthru` making it
    nicer for public use.

    # Example

    ```nix
    fetchHuggingFace {
      url = "https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-BF16.gguf";
      name = "Qwen3.5-0.8B";
      sha256 = "sha256-mnvtQEG3l14Pcfo0Zw0ekCUhO8kpBawNt102xPo/piM=";
    }
    ```

    # Type

    ```
    fetchHuggingFace :: AttrSet -> Derivation
    ```

    # Arguments

    args
    : A attr set of `fetchurl` like args.
  */
  fetchHuggingFace =
    args:
    let
      upstream =
        pkgs.callPackage "${inputs.nixified-ai}/flake-modules/fetchers/fetchresource/default.nix"
          { };
      argsWithPassthru = if args ? passthru then args else args // { passthru = { }; };
    in
    upstream argsWithPassthru;

  /**
    The nix module containing modular services option definitions
    for llama-swap. Import it in a service definition to use.

    See [root](./modules/root.nix) for the actual definitions
    you may use.

    # Example

    ```nix
    services."my-service" = {
      imports = [
        llama-swap-lib.module
      ];

      # Go ahead and use the llama-swap options.
    };
    ```
  */
  module = serviceModule;

  /**
    A formatter for [`lib.cli.toCommandLine`](https://noogle.dev/f/lib/cli/toCommandLine/)
    that produces llama style command options.

    # Example

    ```nix
    lib.cli.toCommandLine llamaOptionFormat {
      model = "my-model";
      port = "8080";
    };

    # Type

    ```
    llamaOptionFormat :: AttrSet -> [String]
    ```

    # Arguments

    optionName
    : The name to format as a llama arg
  */
  llamaOptionFormat = optionName: {
    option = "--${optionName}";
    sep = null;
    explicitBool = true;
  };

  /**
    Create a llama style command string out of a series of
    declarative options.

    # Example

    ```nix
    formatLlamaCmd {
      package = pkgs.llama-cpp;
      args = {
        model = my-model;
        port = 8080;
      };
    }
    # Type

    ```
    formatLlamaCmd :: AttrSet -> String
    ```

    # Arguments

    args
    : A attr set of config options for the llama command
  */
  formatLlamaCmd =
    {
      package,
      exe ? "llama-server",
      args,
    }:
    let
      cliArgs = lib.cli.toCommandLine llamaOptionFormat args;

      scriptArgsString = lib.concatStringsSep " \\\n  " cliArgs;
    in
    "${lib.getExe' package exe} ${scriptArgsString}";
}
