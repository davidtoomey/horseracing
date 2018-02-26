pragma solidity ^0.4.17;

import './HorseBase.sol';
import './HorseCore.sol';

contract TwoPlayerRace is HorseBase, HorseCore  {
    
    string public nameOfRace;
    
    ERC721 public nonFungibleContract;
    
    // Need to eventually work in race events for UI purposes

    // STARTING TO THINK WAGER IS UNNECCESSARY IN CONSTRUCTOR FUNCTION
    
    // HOrseIndexToOwner can't read owner address from this contract
    
    // for this contract to be able to use the different horse ownership 
    // functions, it must be called from HorseCore that's why it can't
    // read HOrseIndexToOwner
    
    // the current race creation process is inefficient because the creator 
    // of a race must undergo multiple transactions from race creation, to
    // entering a horse into a race, to actually racing another horse

    function TwoPlayerRace(address _nftAddress, string _nameOfRace) public {
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
        
        _createRace(_nameOfRace);
        racingPlayers = 0; 
        nameOfRace = _nameOfRace;
    }

    function getNameOfRace() external view returns (string) {
        return nameOfRace;
    }
    
    function playerCount() external view returns (uint) {
        return racingPlayers;
    }
    
    // enum RaceStatus {
    //     Started,
    //     Finished,
    //     Pending,
    //     Cancelled
    // }
    
    struct Race {
        string raceName;
        // uint stake;
        uint horseOneId;
        uint horseTwoId;
        // RaceStatus status;
        uint grandPrize;
        uint horseWinnerId;
        uint horseLoserId;
    }
    
    
    mapping (address => uint[]) addressToRaces;
    Race[] public races;
    uint public racingPlayers;
    
    function _createRace(string _raceName) internal returns (uint) {
        Race memory _race = Race({
            raceName: _raceName,
            // stake: _stake,
            horseOneId: 0,
            horseTwoId: 0,
            // status: RaceStatus.Pending,
            grandPrize: 0,
            horseWinnerId: 0,
            horseLoserId: 0
        });
        uint newRaceId = races.push(_race) - 1;
        
        // RaceCreated(newRaceId, msg.sender);
        
        return newRaceId;
    }
    
    uint public raceGrandPrize;
    
    function _enterRace(uint enterRaceId, uint enterHorseId) public payable {
        // uint weiToEther = msg.value * 1000000000000000000;
        // require(msg.value == races[enterRaceId].stake);
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
            // uint stakeDoubled = races[enterRaceId].stake * 2;
            raceGrandPrize = this.balance;
            _startRace(enterRaceId, races[enterRaceId].horseOneId, races[enterRaceId].horseTwoId);
        }

    }
    
    function _startRace(uint startRaceId, uint hOneId, uint hTwoId) internal {
        require(races[startRaceId].grandPrize > 0);
        // RaceStage(startRaceId);
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
    
    address public winnerAddress;
    uint public winnerId;
    uint public contractBalance = this.balance;

    function pickWinner(uint _raceId, uint _h0rseOneId, uint _h0rseTwoId) internal {
        Horse storage h0rseOne = horses[_h0rseOneId];
        Horse storage h0rseTwo = horses[_h0rseTwoId];
        
        uint rand = randMod(100);
        if (rand <= horseOneProbability) {
            h0rseOne.winCount++;
            h0rseOne.level++;
            h0rseTwo.lossCount++;
            HorseIndexToOwner[_h0rseOneId].transfer(races[_raceId].grandPrize);
            winnerId = _h0rseOneId;
        } else {
            h0rseTwo.winCount++;
            h0rseOne.lossCount++;
            HorseIndexToOwner[_h0rseTwoId].transfer(races[_raceId].grandPrize);
            winnerId = _h0rseTwoId;
        }
        winnerAddress = HorseIndexToOwner[winnerId];
        // RaceEnded(_raceId, winnerAddress);
    }
    
}