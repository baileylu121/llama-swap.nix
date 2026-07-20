# `llama-swap.nix`

Standalone `llama-swap` nix [modular services](https://wiki.nixos.org/wiki/Modular_Services) bindings with fast model fetching powered by [nixified AI](https://github.com/nixified-ai/flake)'s fetchers.

# Usage

## Nix-ified config file

`llama-swap.nix` provides support for generating a `llama-swap` config file
out of `NixOS` style modules, allowing you to split config into multiple files,
type check it, avoid writing yaml, and all the usual goodies:

``` nix
myConfigFile = builtins.toFile (llama-swap.lib.parseLLamaSwapCfg({
 # TODO: add realistic config
});
```

## Running with [`Nimi`](https://github.com/weyl-ai/nimi)

[`Nimi`](https://github.com/weyl-ai/nimi) gives a simple way for us to run these modular services without building a full nixos system or home manager config:

``` nix
default = nimi.mkNimiBin {
  services."llama-example" = {
    imports = [ 
      llama-swap.modules.default
    ];
    
    # TODO: add realistic config
  };
};
```

> This config has some other nice benefits, like free restarts in case of 
> crashing, etc, but if you want you can apply this to any modular
> services host
