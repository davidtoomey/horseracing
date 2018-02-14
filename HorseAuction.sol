pragma solidity ^0.4.18;

import "./HorseBreeding.sol";
import "./Auction/ClockAuction.sol";
import "./Auction/SiringClockAuction.sol";
import "./Auction/SaleClockAuction.sol";

/// @title Handles creating auctions for sale and siring of kitties.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract HorseAuction is HorseBreeding {

    /// @dev The address of the ClockAuction contract that handles sales of Kitties. This
    ///  same contract handles both peer-to-peer sales as well as the gen0 sales which are
    ///  initiated every 15 minutes.
    SaleClockAuction public saleAuction;

    /// @dev The address of a custom ClockAution subclassed contract that handles siring
    ///  auctions. Needs to be separate from saleAuction because the actions taken on success
    ///  after a sales and siring auction are quite different.
    SiringClockAuction public siringAuction;

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Sets the reference to the siring auction.
    /// @param _address - Address of siring contract.
    function setSiringAuctionAddress(address _address) public onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
    }

    /// @dev Put a Horse up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _horseId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If Horse is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _horseId));
        _approve(_horseId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the Horse.
        saleAuction.createAuction(
            _horseId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Put a Horse up for auction to be sire.
    ///  Performs checks to ensure the Horse can be sired, then
    ///  delegates to reverse auction.
    function createSiringAuction(
        uint256 _horseId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If Horse is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _horseId));
        require(isReadyToBreed(_horseId));
        _approve(_horseId, siringAuction);
        // Siring auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the Horse.
        siringAuction.createAuction(
            _horseId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Completes a siring auction by bidding.
    ///  Immediately breeds the winning matron with the sire on auction.
    /// @param _sireId - ID of the sire on auction.
    /// @param _matronId - ID of the matron owned by the bidder.
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        public
        payable
        whenNotPaused
    {
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));
        uint256 currPrice = siringAuction.getCurrentPrice(_sireId);
        uint256 bidAmount = msg.value;
        bool doAutoBirth = false;

        if (bidAmount >= currPrice + autoBirthFee) {
            bidAmount -= autoBirthFee;
            doAutoBirth = true;
        }

        // Siring auction will throw if the bid fails.
        siringAuction.bid.value(bidAmount)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));

        if (doAutoBirth) {
            // Auto birth fee provided, trigger autobirth event
            Horse storage matron = horses[_matronId];
            AutoBirth(_matronId, matron.cooldownEndTime);
        }
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the HorseCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyCOO {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}
