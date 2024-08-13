import AaveFLTaker from "./forge-out/AaveFLTaker.sol/AaveFLTaker.json" assert { type: "json" };
import BatchLiquidator from "./forge-out/BatchLiquidator.sol/BatchLiquidator.json" assert { type: "json" };
import Liquidator from "./forge-out/Liquidator.sol/Liquidator.json" assert { type: "json" };
import PriceHelper from "./forge-out/PriceHelper.sol/PriceHelper.json" assert { type: "json" };
import { writeFileSync } from "node:fs";

const address = "`0x${string}`";

const bytecode = `export const AaveFLTaker_bytecode: ${address} = "${AaveFLTaker.bytecode.object}";
export const BatchLiquidator_bytecode: ${address} = "${BatchLiquidator.bytecode.object}";
export const Liquidator_bytecode: ${address} = "${Liquidator.bytecode.object}";
export const PriceHelper_bytecode: ${address} = "${PriceHelper.bytecode.object}";
`;

writeFileSync("./src/bytecode/bytecode.generated.ts", bytecode, "utf-8");
