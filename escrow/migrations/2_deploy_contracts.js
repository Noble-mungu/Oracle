// migrations/2_deploy_contracts.js
const Escrow = artifacts.require("Escrow");

module.exports = function(deployer) {
  const supplier = "0xSupplierAddress";
  const distributor = "0xDistributorAddress";
  const carrier = "0xCarrierAddress";
  deployer.deploy(Escrow, supplier, distributor, carrier);
};
