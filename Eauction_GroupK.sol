// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract SimpleAuction {
    address public auctioneer;
    uint public auctionEndTime;
    address public seller;
    uint public remEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bidders;
    mapping(address => uint) pendingReturns;
    bool public ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();
    uint public biddingTimeT;
    constructor(
        uint biddingTime,
        address payable auctioneerAddress
    ) {
        auctioneer = auctioneerAddress;
        biddingTimeT = biddingTime;
    }
    function registerBidder() public {
        require(bidders[msg.sender] == 0, "Bidder already registered");
        bidders[msg.sender] = 1;
    }
    function verifyBidder(address bid_add) public {
        require(msg.sender == auctioneer, "Only auctioneer can verify bidders");
        require(bidders[bid_add] == 1, "Bidder not registered or already verified");
        bidders[bid_add] = 2;
    }
    function registerSeller() public {
        require(seller == address(0), "Seller already registered");
        seller = msg.sender;
    }
    function verifySeller() public {
        require(msg.sender == auctioneer, "Only auctioneer can verify seller");
        require(seller != address(0), "Seller not registered yet");
        seller = address(uint160(seller));
        bidders[seller] = 2;
    }
    bool public auctionStarted = false;
    function startAuction() external {
        require(msg.sender == auctioneer, "Only auctioneer can start the auction");
        require(bidders[seller] == 2, "Seller not verified or registered");
        auctionStarted = true;
        auctionEndTime = block.timestamp + biddingTimeT;
    }
    function bid() external payable {
        require(auctionStarted == true, "Auction has not yet started");
        require(bidders[msg.sender] == 2, "Bidder not verified or registered");
        if (block.timestamp > auctionEndTime || ended == true)
            revert AuctionAlreadyEnded();
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);
        payable(highestBidder).transfer(highestBid);
        pendingReturns[msg.sender] = 0;
        if (highestBid != 0) {
            pendingReturns[highestBidder] = highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    
function remEnd() external {
        remEndTime =  auctionEndTime - block.timestamp;
    }
    function auctionEnd() external {
        require(auctionStarted == true, "Auction not started yet");
        require(msg.sender == auctioneer, "Only Auctioneer can call of the auction");
        if (ended)
            revert AuctionEndAlreadyCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        payable(seller).transfer(highestBid);
    }
}