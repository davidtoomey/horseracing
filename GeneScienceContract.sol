pragma solidity ^0.4.18;

// temporary contract to calculate random gene sequence
// will need to make more intricate randomness function for production 
contract GeneScienceContract {
    
    uint geneDigits = 16;
    uint geneModulus = 10 ** geneDigits;
    
    function GeneScienceContract() public {
        
    }
    
    function isGeneScience() public pure returns (bool) {
        return true;
    }
    
    function mixGenes(uint matronId, uint sireId) external view returns (uint) {
        uint yGene = uint(keccak256(matronId));
        uint xGene = uint(keccak256(sireId));
        
        uint rand = uint(keccak256(yGene + xGene));
        
        return rand % geneModulus;
    }
}
