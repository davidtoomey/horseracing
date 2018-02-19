pragma solidity ^0.4.17;

import './HorseRace.sol';
import './Race.sol';
import './HorseBase.sol';
import './Ownable.sol';

contract TwoPlayerRace is Race, Ownable, HorseBase {
    
    HorseRace _base;
    
    function TwoPlayerRace(HorseRace base) public {
        _base = base;
    }

    function name() external view returns (string) {
        return "2PR";
    }
    
    function playerCount() external view returns (uint) {
        return racingPlayers;
    }
    
    enum RaceStatus {
        Started,
        Finished,
        Cancelled
    }
    
    struct Race {
        uint stake;
        Horse horseOne;
        Horse horseTwo;
        RaceStatus status;
        uint grandPrize;
        address raceWinner;
    }
    
    
    mapping (address => uint[]) addressToRaces;
    Race[] public races;
    uint public racingPlayers;
    
    // function decideWinner(uint _raceId, Race.Horse winner, Race.Horse loser) internal {
    //     Race storage _race = races[_raceId];
    //     // setProbabilities(_horseOne, _horseTwo);
    // }
    
    // function setProbabilities(uint _horseOneId, uint _horseTwoId) internal {
    //     uint horseOneLevel = Horse[_horseOneId];
    // }
    
}