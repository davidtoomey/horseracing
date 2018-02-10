pragma solidity ^0.4.19;

import "./Ownable.sol";

contract HorseFactory is Ownable {

    event NewHorse(uint horseId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 days;

    struct Horse {
        string name;
        uint dna;
        uint32 level;
        uint16 winCount;
        uint16 lossCount;
    }

    Horse[] public horses;

    mapping (uint => address) public horseToOwner;
    mapping (address => uint) public ownerHorseCount;

    function _createHorse(string _name, uint _dna) internal {
        uint id = horses.push(Horse(_name, _dna, 0, 0, 0)) - 1;
        horseToOwner[id] = msg.sender;
        ownerHorseCount[msg.sender]++;
        NewHorse(id, _name, _dna);
    }

    function _generateRandomDna(string _str) private view returns (uint) {
        uint rand = uint(keccak256(_str));
        return rand % dnaModulus;
    }

    function createRandomHorse(string _name) public {
        require(ownerHorseCount[msg.sender] == 0);
        uint randDna = _generateRandomDna(_name);
        randDna = randDna - randDna % 100;
        _createHorse(_name, randDna);
    }
}
