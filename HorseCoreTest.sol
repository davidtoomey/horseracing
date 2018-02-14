pragma solidity ^0.4.18;

import './HorseCore.sol';


/// @title Horse core with extra test fn and overrides
contract HorseCoreTest is HorseCore {
    // https://ethereum.stackexchange.com/questions/16318/inherited-constructors
    function HorseCoreTest() public {
    }

    /*** ALL TEST FUNCTIONS GO HERE: ***/

    /// @dev Contract owner can create Horses at will (test-only)
    /// @param _genes the actual genetic load of Horses
    /// @param _cloneCount how many are being created
    function mintHorses(uint256 _genes, uint32 _cloneCount) public onlyCOO whenNotPaused {
        // NOTE: this method should be removed after ETHWaterloo
        // require(_genes > 0);
        require(_cloneCount > 0);

        for (uint256 i = 0; i < _cloneCount; i++) {
            _createHorse(0, 0, 0, _genes, msg.sender);
        }
    }

    /// @dev for tests we can easily fund the contract
    function fundMe() public payable returns (bool) {
        return true;
    }

    function timeNow() public constant returns (uint256) {
        return now;
    }
}
