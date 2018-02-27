pragma solidity ^0.4.17;

import './HorseOwnership.sol';
import './StageRace.sol';

contract HorseRacing is HorseOwnership {
    
    // reference to TwoPlayerRace contract
    TwoPlayerRace public twoPlayerRace;
    
    function setRaceAddress(address _address) public onlyCEO {
        
        TwoPlayerRace candidateContract = TwoPlayerRace(_address);
        
        require(candidateContract.isRacingAddress());
        
        twoPlayerRace = candidateContract;
    }
    
    // the person who creates a race gets assigned as playerOne
    function createNewRace(string _raceName, uint _horseId, uint _wager) public whenNotPaused {
        require(_owns(msg.sender, _horseId));
        require(_wager > 0);
        
        twoPlayerRace._createRace(_raceName, _horseId, _wager, msg.sender);
    }
    
    // the person who joins an existing race gets assigned as player two
    function joinExistingRace(uint _raceId, uint _horseId) public payable whenNotPaused {
        require(_owns(msg.sender, _horseId));
        // require msg.sender to send the same amount of ether as player1
        twoPlayerRace._enterRace(_raceId, _horseId);
    }
    
    // function cancelRace(uint _raceId, address playerAddress) public {
        
    // }
    
}