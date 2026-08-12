# `llama-swap.nix`

Standalone `llama-swap` nix [modular services](https://wiki.nixos.org/wiki/Modular_Services) bindings with fast model fetching powered by [nixified AI](https://github.com/nixified-ai/flake)'s fetchers.

# Usage

## Nix-ified config file

`llama-swap.nix` provides support for generating a `llama-swap` config file
out of `NixOS` style modules, allowing you to split config into multiple files,
type check it, avoid writing yaml, and all the usual goodies:

``` nix
myConfigFile = llama-swap-lib.writeLLamaSwapCfgFile {
  # Load qwen 3.5 0.8B with llama-server
  # You can add more than one model here
  models."Qwen3.5-0.8B" = {
    cmd = ''
      ${lib.getExe' pkgs.llama-cpp "llama-server"} \
      --model ${qwen} \
      --port 16234
    '';
    proxy = "http://localhost:16234";
  };
};
```

## Running with [`Nimi`](https://github.com/weyl-ai/nimi)

[`Nimi`](https://github.com/weyl-ai/nimi) gives a simple way for us to run these modular services without building a full nixos system or home manager config:

``` nix
default = nimi.mkNimiBin {
  services."llama-example" = {
    imports = [ 
      llama-swap.modules.default
    ];
    
    # <put config here>
  };
};
```

> This config has some other nice benefits, like free restarts in case of 
> crashing, etc, but if you want you can apply this to any modular
> services host

You can see this materialized properly in [`examples/simple-qwen.nix`](./examples/simple-qwen.nix).

# `llama-swap-lib`

`llama-swap-lib` is bound to the flake output `self.lib.${system}`, and contains some nice utility functions for configuring llama-swap with nix. 

If you want docs for the functions it contains you should check out [`lib.nix`](./lib.nix).
