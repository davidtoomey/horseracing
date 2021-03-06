pragma solidity ^0.4.18;

import "./HorseAccessControl.sol";


/// @title Base contract for Cryptohorses. Holds all common structs, events and base variables.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the HorseCore contract documentation to understand how the various contract facets are arranged.
contract HorseBase is HorseAccessControl {
    /*** EVENTS ***/

    /// @dev The Birth event is fired whenever a new Horse comes into existence. This obviously
    ///  includes any time a cat is created through the giveBirth method, but it is also called
    ///  when a new gen0 cat is created.
    event Birth(address indexed owner, uint256 horseId, uint256 matronId, uint256 sireId, uint256 genes);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a Horse
    ///  ownership is assigned, including births.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*** DATA TYPES ***/

    /// @dev The main Horse struct. Every cat in Cryptohorses is represented by a copy
    ///  of this structure, so great care was taken to ensure that it fits neatly into
    ///  exactly two 256-bit words. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Horse {
        // The Horse's genetic code is packed into these 256-bits, the format is
        // sooper-sekret! A cat's genes never change.
        uint256 genes;

        // The timestamp from the block when this cat came into existence.
        uint64 birthTime;

        // The minimum timestamp after which this cat can engage in breeding
        // activities again. This same timestamp is used for the pregnancy
        // timer (for matrons) as well as the siring cooldown.
        uint64 cooldownEndTime;

        // The ID of the parents of this Horse, set to 0 for gen0 cats.
        // Note that using 32-bit unsigned integers limits us to a "mere"
        // 4 billion cats. This number might seem small until you realize
        // that Ethereum currently has a limit of about 500 million
        // transactions per year! So, this definitely won't be a problem
        // for several years (even as Ethereum learns to scale).
        uint32 matronId;
        uint32 sireId;

        // Set to the ID of the sire cat for matrons that are pregnant,
        // zero otherwise. A non-zero value here is how we know a cat
        // is pregnant. Used to retrieve the genetic material for the new
        // Horse when the birth transpires.
        uint32 siringWithId;

        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this Horse. This starts at zero
        // for gen0 cats, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action, regardless
        // of whether this cat is acting as matron or sire.
        uint16 cooldownIndex;

        // The "generation number" of this cat. Cats minted by the CK contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other cats is the larger of the two generation
        // numbers of their parents, plus one.
        // (i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;
        uint16 level;
        uint16 winCount;
        uint16 lossCount;
    }

    /*** CONSTANTS ***/

    /// @dev A lookup table indicating the cooldown duration after any successful
    ///  breeding action, called "pregnancy time" for matrons and "siring cooldown"
    ///  for sires. Designed such that the cooldown roughly doubles each time a cat
    ///  is bred, encouraging owners not to just keep breeding the same cat over
    ///  and over again. Caps out at one week (a cat can breed an unbounded number
    ///  of times, and the maximum cooldown is always seven days).
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    /*** STORAGE ***/

    /// @dev An array containing the Horse struct for all horses in existence. The ID
    ///  of each cat is actually an index into this array. Note that ID 0 is a negacat,
    ///  the unHorse, the mythical beast that is the parent of all gen0 cats. A bizarre
    ///  creature that is both matron and sire... to itself! Has an invalid genetic code.
    ///  In other words, cat ID 0 is invalid... ;-)
    Horse[] horses;

    /// @dev A mapping from cat IDs to the address that owns them. All cats have
    ///  some valid owner address, even gen0 cats are created with a non-zero owner.
    mapping (uint => address) public HorseIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from horseIds to an address that has been approved to call
    ///  transferFrom(). Each Horse can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public HorseIndexToApproved;

    /// @dev A mapping from horseIds to an address that has been approved to use
    ///  this Horse for siring via breedWith(). Each Horse can only have one approved
    ///  address for siring at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public sireAllowedToAddress;

    /// @dev Assigns ownership of a specific Horse to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // since the number of Horses is capped to 2^32
        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        HorseIndexToOwner[_tokenId] = _to;
        // When creating new Horses _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // once the Horse is transferred also clear sire allowances
            delete sireAllowedToAddress[_tokenId];
            // clear any previously approved ownership exchange
            delete HorseIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new Horse and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _matronId The Horse ID of the matron of this cat (zero for gen0)
    /// @param _sireId The Horse ID of the sire of this cat (zero for gen0)
    /// @param _generation The generation number of this cat, must be computed by caller.
    /// @param _genes The Horse's genetic code.
    /// @param _owner The inital owner of this cat, must be non-zero (except for the unHorse, ID 0)
    function _createHorse(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        // These requires are not strictly necessary, our calling code should make
        // sure that these conditions are never broken. However! _createHorse() is already
        // an expensive call (for storage), and it doesn't hurt to be especially careful
        // to ensure our data structures are always valid.
        require(_matronId <= 4294967295);
        require(_sireId <= 4294967295);
        require(_generation <= 65535);

        Horse memory _horse = Horse({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndTime: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: 0,
            generation: uint16(_generation),
            level: 0,
            winCount: 0,
            lossCount: 0
        });
        uint256 newHorseId = horses.push(_horse) - 1;

        // It's probably never going to happen, 4 billion cats is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newHorseId <= 4294967295);

        // emit the birth event
        Birth(
            _owner,
            newHorseId,
            uint256(_horse.matronId),
            uint256(_horse.sireId),
            _horse.genes
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newHorseId);

        return newHorseId;
    }
}
