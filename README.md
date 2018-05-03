# Auction engine

This project is for practicing and learning purposes only. It's been developed as final work for the Solidity programming course, dictated at https://ripiocredit.network/.

## Features

The `AuctionEngine` contract allow users to create auctions for any ERC721 digital asset, and accept any ERC20 valid token in exchange for it.

Every auction will follow these rules:

* In order to create an Auction, the sender of the transaction must be the owner of the digital asset that will take place in that auction. The owner must also approve the engine to transfer the asset before creating the Auction.

* Auction creator will determine the `startTime` and `startPrice` during the creation.

* Every time a bidder submits a new bid, tokens are transferred to the engine contract.

* If a better bid is submitted, funds are transferred back to the previous bidder (if any), and funds from the new better bidder are, again, stored in the engine contract.

* Auctions are only accepting bids while `isFinished(auctionIndex) == false`.

* Once an Auction is over, both Auction creator and winner have the right to claim. Auction creator will claim the amount of tokens that won the auction, and Auction winner will claim the digital asset.

## Testing

`AuctionEngine` contract is tested using the truffle framework, mocha library, and async await JS functions.

To run tests, make sure to have the proper dependencies installed, and run:

```
$ truffle test

Contract: AuctionEngine
  ✓ initializes with empty list of auctions
  ✓ should create an auction (181ms)
  ✓ should not create auction if asset was not previously approved (68ms)
  ✓ should not create auction if msg.sender is not the asset owner (88ms)
  ✓ should bid and transfer tokens to the auction engine (271ms)
  ✓ should transfer the asset to the winner and tokens to the creator when auction is claimed (1592ms)


6 passing (4s)
```

## Final notes

The `AuctionEngine` contract has been deployed in the Ropsten Ethereum testing network, under this address: `0xd61f183ffadd5e0f5a1734e7d40724455a9e620a`.

Feel free to interact with it, or check more details in the Etherscan overview:
https://ropsten.etherscan.io/address/0xd61f183ffadd5e0f5a1734e7d40724455a9e620a
