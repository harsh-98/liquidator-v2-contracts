import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "src/abi/abi.generated.ts",
  plugins: [
    foundry({
      project: ".",
      artifacts: "forge-out/",
      include: [
        "AaveFLTaker.sol/AaveFLTaker.json",
        "AaveLiquidator.sol/AaveLiquidator.json",
        "BatchLiquidator.sol/BatchLiquidator.json",
        "GhoFMTaker.sol/GhoFMTaker.json",
        "GhoLiquidator.sol/GhoLiquidator.json",
        "IBatchLiquidator.sol/IBatchLiquidator.json",
        "IGhoFlashMinter.sol/IGhoFlashMinter.json",
        "IPartialLiquidator.sol/IPartialLiquidator.json",
        "IPriceHelper.sol/IPriceHelper.json",
        "PriceHelper.sol/PriceHelper.json",
      ],
      forge: {
        clean: false,
        build: false,
        rebuild: false,
      },
    }),
  ],
});
