pragma solidity ^0.4.2;

import "./SafeMath.sol";
import "./AddressUtils.sol";
import "./ERC20.sol";
import "./ERC721.sol";

import "./MZToken.sol";


contract AuctionEngine {
    using SafeMath for uint256;
    using AddressUtils for address;

    event AuctionCreated(uint256 _index, address _creator, address _asset, address _token);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
    event Claim(uint256 auctionIndex, address claimer);

    enum Status { pending, active, finished }
    struct Auction {
        address assetAddress;
        uint256 assetId;
        address tokenAddress;

        address creator;

        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
    }
    Auction[] private auctions;

    function createAuction(address _assetAddress,
                           uint256 _assetId,
                           address _tokenAddress,
                           uint256 _startPrice,
                           uint256 _startTime,
                           uint256 _duration) public returns (uint256) {

        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));

        require(_tokenAddress.isContract());

        if (_startTime == 0) { _startTime = now; }

        Auction memory auction = Auction({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            tokenAddress: _tokenAddress,
            startTime: _startTime,
            duration: _duration,
            currentBidAmount: _startPrice,
            currentBidOwner: address(0),
            bidCount: 0
        });
        uint256 index = auctions.push(auction) - 1;

        emit AuctionCreated(index, auction.creator, auction.assetAddress, auction.tokenAddress);

        return index;
    }

    function bid(uint256 auctionIndex, uint256 amount) public returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator != address(0));
        require(isActive(auctionIndex));

        if (amount > auction.currentBidAmount) {
            // we got a better bid. Return tokens to the previous best bidder
            // and register the sender as `currentBidOwner`
            ERC20 token = ERC20(auction.tokenAddress);
            require(token.transferFrom(msg.sender, address(this), amount));
            if (auction.currentBidAmount != 0) {
                // return funds to the previuos bidder
                token.transfer(
                    auction.currentBidOwner,
                    auction.currentBidAmount
                );
            }
            // register new bidder
            auction.currentBidAmount = amount;
            auction.currentBidOwner = msg.sender;
            auction.bidCount = auction.bidCount.add(1);

            emit AuctionBid(auctionIndex, msg.sender, amount);
            return true;
        }
        return false;
    }

    function getTotalAuctions() public view returns (uint256) { return auctions.length; }

    function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }

    function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }

    function getStatus(uint256 index) public view returns (Status) {
        Auction storage auction = auctions[index];
        if (now < auction.startTime) {
            return Status.pending;
        } else if (now < auction.startTime.add(auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }

    function getCurrentBidOwner(uint256 auctionIndex) public view returns (address) { return auctions[auctionIndex].currentBidOwner; }

    function getCurrentBidAmount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].currentBidAmount; }

    function getBidCount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].bidCount; }

    function getWinner(uint256 auctionIndex) public view returns (address) {
        require(isFinished(auctionIndex));
        return auctions[auctionIndex].currentBidOwner;
    }

    function claimTokens(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];

        require(auction.creator == msg.sender);
        ERC20 token = ERC20(auction.tokenAddress);
        require(token.transfer(auction.creator, auction.currentBidAmount));

        emit Claim(auctionIndex, auction.creator);
    }

    function claimAsset(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];

        address winner = getWinner(auctionIndex);
        require(winner == msg.sender);

        ERC721 asset = ERC721(auction.assetAddress);
        asset.transferFrom(auction.creator, winner, auction.assetId);

        emit Claim(auctionIndex, winner);
    }
}
