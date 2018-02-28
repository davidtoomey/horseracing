pragma solidity ^0.4.17;

// this contract throws an error because TwoPlayerRace's
// functions are unwritten

import './HorseOwnership.sol';
import './TwoPlayerRace.sol';

contract HorseRacing is HorseOwnership {
    
    // reference to TwoPlayerRace contract
    TwoPlayerRace public twoPlayerRace;
    
    // function setRaceAddress(address _address) public onlyCEO {
        
    //     TwoPlayerRace candidateContract = TwoPlayerRace(_address);
        
    //     require(candidateContract.isRacingAddress());
        
    //     twoPlayerRace = candidateContract;
    // }
    
    function createNewRace(string _raceName, uint _horseId) external payable {
        require(_owns(msg.sender, _horseId));
        require(msg.value > 0);
        
        twoPlayerRace.createRace(_raceName, _horseId, msg.sender);
    }
    
    function joinExistingRace(uint _raceId, uint _horseId) public payable whenNotPaused {
        
        
        twoPlayerRace.enterRace(_raceId, _horseId, msg.sender);
    }
    
}