pragma solidity ^0.4.17;

contract Race {
    // the name of the Race type
    function name() external view returns (string);
    // the number of robots currently battling
    function playerCount() external view returns (uint count);
    function createRace(address _creator, uint[] horseIds) external payable;
    function enterRace() external payable;
    // // cancels the Race at RaceID
    function cancelRace(uint raceID) external;

    event RaceCreated(uint indexed raceID, address indexed starter);
    event RaceStage(uint indexed raceID);
    event RaceEnded(uint indexed raceID, address indexed winner);
    // event RaceConcluded(uint indexed raceID);
}