# If you are new to this, this is a nimi module options tree, and not a nixos one
# though they may look similar
{
  llama-swap-lib,
  lib,
  pkgs,
  ...
}:
{
  _class = "nimi";

  # Regular modular services config here:
  services."llama-example" = {
    imports = [ llama-swap-lib.module ];

    config.llama-swap.config =
      let
        # Custom fetcher that uses HF_TOKEN if you have it set
        # to get around rate limits
        qwen = llama-swap-lib.fetchHuggingFace {
          url = "https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-BF16.gguf";
          name = "Qwen3.5-0.8B";
          sha256 = "sha256-mnvtQEG3l14Pcfo0Zw0ekCUhO8kpBawNt102xPo/piM=";
        };
      in
      llama-swap-lib.writeLLamaSwapCfgFile {
        # Load qwen 3.5 0.8B with llama-server
        # You can add more than one model here
        models."Qwen3.5-0.8B" = {
          cmd = llama-swap-lib.formatLlamaCmd {
            package = pkgs.llama-cpp;
            args = {
              model = qwen;
              port = 16234;
            };
          };
          proxy = "http://localhost:16234";
        };
      };
  };
}
