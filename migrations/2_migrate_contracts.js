var MZToken = artifacts.require("./MZToken.sol");
var BookToken = artifacts.require("./BookToken.sol");
var AuctionEngine = artifacts.require("./AuctionEngine.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(MZToken, {from: accounts[0]});
  deployer.deploy(BookToken, {from: accounts[1]});
  deployer.deploy(AuctionEngine);
};
