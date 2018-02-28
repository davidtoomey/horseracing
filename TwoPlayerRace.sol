pragma solidity ^0.4.17;

import './HorseBase.sol';
import './HorseOwnership.sol';
import './Race.sol';

// Instead of inheriting HorseBase and HorseOwnership directly here, we will do the horse 
// related ownership checks in HorseRacing
contract TwoPlayerRace is Race {
    // an array of Race contracts to keep track of races
    Race[] races;
    
    struct Duel {
        
    }
    
    struct Challenger {
        
    }
    
    // gets the horseID of the challenger of a given a duel
    mapping (uint => Challenger[]) duelIdToChallengers;
    
    function createRace() {
        
    }
}