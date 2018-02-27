pragma solidity ^0.4.18;

// // Auction wrapper functions
import "./HorseMinting.sol";

// // Racing wrapper functions
import "./HorseRacing.sol";

// Main Horse contract
contract HorseCore is HorseMinting, HorseRacing {

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main Cryptohorses smart contract instance.
    function HorseCore() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // start with the mythical newHorse 0 - so we don't have generation-0 parent issues
        _createHorse(0, 0, 0, uint256(-1), address(0));
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) public onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

    /// @notice Returns all the relevant information about a specific Horse.
    /// @param _id The ID of the Horse of interest.
    function getHorse(uint256 _id)
        public
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes,
        uint level,
        uint winCount,
        uint lossCount
    ) {
        Horse storage thisHorse = horses[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (thisHorse.siringWithId != 0);
        isReady = (thisHorse.cooldownEndTime <= now);
        cooldownIndex = uint256(thisHorse.cooldownIndex);
        nextActionAt = uint256(thisHorse.cooldownEndTime);
        siringWithId = uint256(thisHorse.siringWithId);
        birthTime = uint256(thisHorse.birthTime);
        matronId = uint256(thisHorse.matronId);
        sireId = uint256(thisHorse.sireId);
        generation = uint256(thisHorse.generation);
        genes = thisHorse.genes;
        level = thisHorse.level;
        winCount = thisHorse.winCount;
        lossCount = thisHorse.lossCount;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    function getContractBalance() public view returns(uint) {
        return this.balance;
    }
}