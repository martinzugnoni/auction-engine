var MZToken = artifacts.require("./MZToken.sol");
var BookToken = artifacts.require("./BookToken.sol");
var AuctionEngine = artifacts.require("./AuctionEngine.sol");


contract("AuctionEngine", function(accounts) {
  var token;
  var book;
  var engine;

  beforeEach("create instances of token, book and engine contracts", async function(){
      token = await MZToken.new({from: accounts[0]});
      book = await BookToken.new({from: accounts[1]});
      engine = await AuctionEngine.new({from: accounts[2]});
  })

  async function assertThrow(promise) {
      try {
          await promise;
      } catch (error) {
          const revert = error.message.search('revert') >= 0;
          assert(revert, "Expected throw, got '" + error + "' instead");
          return;
      }
      assert.fail('Expected throw not received');
  };

  function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
  }

  it("initializes with empty list of auctions", async function() {
      let count = await engine.getTotalAuctions();
      assert.equal(count, 0);
  });

  it("should create an auction", async function() {
      // make sure account[1] is owner of the book
      let owner = await book.ownerOf(0);
      assert.equal(owner, accounts[1]);

      // allow engine to transfer the book
      await book.approve(engine.address, 0, {from: accounts[1]});

      // create auction
      await engine.createAuction(book.address, 0, token.address, 0, 0, 10, {from: accounts[1]});

      // make sure auction was created
      let count = await engine.getTotalAuctions();
      assert.equal(count, 1);
  });

  it("should not create auction if asset was not previously approved", async function() {
      let approved = await book.getApproved(0);
      assert.equal(approved, 0x0);

      await assertThrow(
        engine.createAuction(book.address, 0, token.address, 0, 0, 10, {from: accounts[1]})
      );
  });

  it("should not create auction if msg.sender is not the asset owner", async function() {
      let owner = await book.ownerOf(0);
      assert.equal(owner, accounts[1]);

      // allow engine to transfer the book
      await book.approve(engine.address, 0, {from: accounts[1]});

      await assertThrow(
        engine.createAuction(book.address, 0, token.address, 0, 0, 10, {from: accounts[0]})  // accounts[0] is not the owner
      );
  });

  it("should bid and transfer tokens to the auction engine", async function() {
      // allow engine to transfer the book
      await book.approve(engine.address, 0, {from: accounts[1]});

      // create auction
      await engine.createAuction(book.address, 0, token.address, 0, 0, 10, {from: accounts[1]});

      let beforeBalance = await token.balanceOf(accounts[0]);
      let initialBalance = 1000 * (10**6);
      assert.equal(beforeBalance, initialBalance);

      // before bidding we need to allow the engine to transfer the tokens
      await token.approve(engine.address, 1000, {from: accounts[0]});

      // place the bid
      await engine.bid(0, 1000, {from: accounts[0]});

      let afterBalance = await token.balanceOf(accounts[0]);
      assert.equal(afterBalance, initialBalance - 1000);

      let engineBalance = await token.balanceOf(engine.address);
      assert.equal(engineBalance, 1000);
  });


  it("should transfer the asset to the winner and tokens to the creator when auction is claimed", async function(){
      // allow engine to transfer the book
      await book.approve(engine.address, 0, {from: accounts[1]});

      // create auction
      await engine.createAuction(book.address, 0, token.address, 0, 0, 1, {from: accounts[1]});  // 1 second auction

      // before bidding we need to allow the engine to transfer the tokens
      await token.approve(engine.address, 1000, {from: accounts[0]});

      // place the bid
      await engine.bid(0, 1000, {from: accounts[0]});

      await sleep(1000)  // sleep 1 second until auction is finished

      let isFinished = await engine.isFinished(0);
      assert.equal(isFinished, true);

      let winner = await engine.getWinner(0);
      assert.equal(winner, accounts[0]);

      // precondition: before claiming, accounts[0] has no assets
      // all books belong to accounts[1]
      let assetCountAccount0 = await book.balanceOf(accounts[0]);
      assert.equal(assetCountAccount0.toNumber(), 0);
      let assetCountAccount1 = await book.balanceOf(accounts[1]);
      assert.equal(assetCountAccount1.toNumber(), 3);

      // auction winner claims the asset
      await engine.claimAsset(0, {from: accounts[0]});

      // poscondition: book that participated in the auction must
      // be transfered to the auction winner
      assetCountAccount0 = await book.balanceOf(accounts[0]);
      assert.equal(assetCountAccount0.toNumber(), 1);
      assetCountAccount1 = await book.balanceOf(accounts[1]);
      assert.equal(assetCountAccount1.toNumber(), 2);

      let bookOwner = await book.ownerOf(0);
      assert.equal(bookOwner, accounts[0]);

      // balances preconditions
      let initialBalance = 1000 * (10**6);
      let bidAmount = 1000
      let tokenBalanceAccount0 = await token.balanceOf(accounts[0]);
      assert.equal(tokenBalanceAccount0.toNumber(), initialBalance - bidAmount);
      let tokenBalanceEngine = await token.balanceOf(engine.address);
      assert.equal(tokenBalanceEngine.toNumber(), bidAmount);
      let tokenBalanceAccount1 = await token.balanceOf(accounts[1]);
      assert.equal(tokenBalanceAccount1.toNumber(), 0);

      // auction creator claims the tokens
      await engine.claimTokens(0, {from: accounts[1]});

      // balances posconditions
      tokenBalanceAccount0 = await token.balanceOf(accounts[0]);
      assert.equal(tokenBalanceAccount0.toNumber(), initialBalance - bidAmount);
      tokenBalanceEngine = await token.balanceOf(engine.address);
      assert.equal(tokenBalanceEngine.toNumber(), 0);
      tokenBalanceAccount1 = await token.balanceOf(accounts[1]);
      assert.equal(tokenBalanceAccount1.toNumber(), bidAmount);
  });
});
