pragma solidity ^0.4.17;

import './HorseRace.sol';
import './Race.sol';
import './HorseBase.sol';
import './HorseCore.sol';
import './Ownable.sol';

contract TwoPlayerRace is Race, HorseRace, Ownable, HorseBase, HorseCore  {
    
    HorseRace _base;

    function TwoPlayerRace(string nameOfRace, uint wager) public {
        // uint raceGrandPrize = wager*2;
        _createRace(nameOfRace, wager);
        racingPlayers = 0;
    }

    // function name() external view returns (string) {
    //     return "2PR";
    // }
    
    function playerCount() external view returns (uint) {
        return racingPlayers;
    }
    
    enum RaceStatus {
        Started,
        Finished,
        Pending,
        Cancelled
    }
    
    struct Race {
        string raceName;
        uint stake;
        uint horseOneId;
        uint horseTwoId;
        RaceStatus status;
        uint grandPrize;
        uint horseWinnerId;
        uint horseLoserId;
    }
    
    
    mapping (address => uint[]) addressToRaces;
    Race[] public races;
    uint public racingPlayers;
    
    function _createRace(
        string _raceName, 
        uint _stake 
        // uint _horseOneId, 
        // uint _horseTwoId,
        // RaceStatus _status,
        // uint _grandPrize,
        // uint _horseWinnerId,
        // uint _horseLoserId
        
    )   internal 
        returns (uint) 
    {
        Race memory _race = Race({
            raceName: _raceName,
            stake: _stake,
            horseOneId: 0,
            horseTwoId: 0,
            status: RaceStatus.Pending,
            grandPrize: 0,
            horseWinnerId: 0,
            horseLoserId: 0
        });
        uint newRaceId = races.push(_race) - 1;
        
        RaceCreated(newRaceId, msg.sender);
        
        return newRaceId;
    }
    
    function _enterRace(uint enterRaceId, uint enterHorseId) public payable {
        require(msg.value > races[enterRaceId].stake);
        require(HorseIndexToOwner[enterHorseId] == msg.sender);
        require(racingPlayers < 2);
        
        if (races[enterRaceId].horseOneId == 0) {
            races[enterRaceId].horseOneId = enterHorseId;
        }
        
        if (races[enterRaceId].horseTwoId == 0) {
            races[enterRaceId].horseTwoId = enterHorseId;
        }
        
        racingPlayers++;
        
        if (racingPlayers == 2) {
            uint setGrandPrize = msg.value*2;
            setGrandPrize = races[enterRaceId].grandPrize;
            _startRace(enterRaceId, races[enterRaceId].horseOneId, races[enterRaceId].horseTwoId);
        }

    }
    
    function _startRace(uint startRaceId, uint hOneId, uint hTwoId) internal {
        require(races[startRaceId].grandPrize > 0);
        RaceStage(startRaceId);
        calculateProbabilities(startRaceId, hOneId, hTwoId);
    }
    
    uint horseOneProbability;
    uint horseTwoProbability;
    
    function calculateProbabilities(uint _raceId, uint _hOneId, uint _hTwoId) internal {
        uint horseOneLevel = horses[_hOneId].level;
        uint horseTwoLevel = horses[_hTwoId].level;
        uint horseOneLevelDiff = horseOneLevel - horseTwoLevel;
        uint horseTwoLevelDiff = horseTwoLevel - horseOneLevel;
        uint horseOneWinProbability;
        uint horseTwoWinProbability;
        
        if (horseOneLevel == horseTwoLevel) {
            horseOneWinProbability = 50;
            horseTwoWinProbability = 50;
        }
        if (horseOneLevelDiff >= 5) {
            horseOneWinProbability = 75;
            horseTwoWinProbability = 25;
        }
        if (horseTwoLevelDiff >= 5) {
            horseOneWinProbability = 25;
            horseTwoWinProbability = 75;
        }
        if (horseOneLevelDiff <= 4) {
            horseOneWinProbability = 60;
            horseTwoWinProbability = 40;
        }
        if (horseTwoLevelDiff <= 4) {
            horseOneWinProbability = 40;
            horseTwoWinProbability = 60;
        }
        
        horseOneWinProbability = horseOneProbability;
        horseTwoWinProbability = horseTwoProbability;
        
        pickWinner(_raceId, horseOneProbability, horseTwoProbability);
    }
    
    uint randNonce = 0;
    
    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
    }

    function pickWinner(uint _raceId, uint _h0rseOneId, uint _h0rseTwoId) internal {
        Horse storage h0rseOne = horses[_h0rseOneId];
        Horse storage h0rseTwo = horses[_h0rseTwoId];
        
        uint rand = randMod(100);
        if (rand <= horseOneProbability) {
            h0rseOne.winCount++;
            h0rseOne.level++;
            h0rseTwo.lossCount++;
            HorseIndexToOwner[_h0rseOneId].transfer(races[_raceId].grandPrize);
        } else {
            h0rseTwo.winCount++;
            h0rseOne.lossCount++;
            HorseIndexToOwner[_h0rseTwoId].transfer(races[_raceId].grandPrize);
        }
    }
    
}