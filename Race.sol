pragma solidity ^0.4.17;

contract Race {
    // This struct does not exist outside the context of a Race

    // the name of the Race type
    function name() external view returns (string);
    // the number of robots currently battling
    function playerCount() external view returns (uint count);
    // creates a new Race, with a submitted user string for initial input/
    function createRace(string _raceName) external payable;
    // cancels the Race at RaceID
    function cancelRace(uint raceID) external;

    // TODO: parameters for these: as generic as possible
    // favour over-reporting/flexibility
    event RaceCreated(uint indexed raceID, address indexed starter);
    event RaceStage(uint indexed raceID);
    event RaceEnded(uint indexed raceID, address indexed winner);
    event RaceConcluded(uint indexed raceID);
    // event RacePropertyChanged(string name, uint previous, uint value);
}