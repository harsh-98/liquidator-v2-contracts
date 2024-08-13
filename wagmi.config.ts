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
        "BatchLiquidator.sol/BatchLiquidator.json",
        "IBatchLiquidator.sol/IBatchLiquidator.json",
        "ILiquidator.sol/ILiquidator.json",
        "Liquidator.sol/Liquidator.json",
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
