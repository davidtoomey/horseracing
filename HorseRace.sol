pragma solidity ^0.4.17;

import './Race.sol';
import './HorseAccessControl.sol';

contract HorseRace is HorseAccessControl {
    
    Race[] approvedRaces;
    
    function addApprovedRace(Race _race) external onlyCEO {
        approvedRaces.push(_race);
    }

    function _isApprovedRace() internal view returns (bool) {
        for (uint8 i = 0; i < approvedRaces.length; i++) {
            if (msg.sender == address(approvedRaces[i])) {
                return true;
            }
        }
        return false;
    }

    modifier onlyApprovedRaces(){
        require(_isApprovedRace());
        _;
    }

}