import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ProofModule", (m) => {
  const proof = m.contract("ProofSmartContract");


  return { proof };
});



// Deployed Addresses

// ProofModule#ProofSmartContract - 0xbf16c7cA893c075758bc18f66d5A993372A6914d