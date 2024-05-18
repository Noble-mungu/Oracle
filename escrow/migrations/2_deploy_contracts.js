// migrations/2_deploy_contracts.js
const Escrow = artifacts.require("Escrow");

module.exports = function(deployer) {
  const supplier = "0xaFC8c5B317fa2d4cC14BcaDD486546E8E5D089F2"; // Supplier address from Ganache
  const distributor = "0x0C8A9E91d56f21c70A0649c7792382b1D1a9f79B"; // Distributor address from Ganache
  const carrier = "0x521F1A4A7d023f626457a1824DcFdbB2728df854"; 
  deployer.deploy(Escrow, supplier, distributor, carrier);
};
