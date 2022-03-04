
/*
 /$$$$$$$$                                /$$$$$$                  /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
|_____ $$                                /$$__  $$                | $$          | $$$ | $$| $$_____/|__  $$__/
     /$$/   /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$ | $$$$| $$| $$         | $$
    /$$/   /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$ $$ $$| $$$$$      | $$
   /$$/   | $$$$$$$$| $$  \__/| $$  \ $$| $$      | $$  \ $$| $$  | $$| $$$$$$$$| $$  $$$$| $$__/      | $$
  /$$/    | $$_____/| $$      | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$_____/| $$\  $$$| $$         | $$
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$         | $$
|________/ \_______/|__/       \______/  \______/  \______/  \_______/ \_______/|__/  \__/|__/         |__/

Drop Your NFT Collection With ZERO Coding Skills at https://zerocodenft.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RebelCartel is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    enum SalesWave{ PAUSED, WAVE1, WAVE2, WAVE3 }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 5000;
    uint public constant TOKENS_PER_TRAN_LIMIT = 2;
    uint public constant WAVE1_PRICE = 0.8 ether;
    uint public constant WAVE2_PRICE = 0.18 ether;
    uint public constant WAVE3_PRICE = 0.08 ether;
    uint public constant WAVE1_LIMIT = 25;
    uint public constant WAVE2_LIMIT = 250;
    uint public constant WAVE3_LIMIT = 4725;

    SalesWave public saleWave = SalesWave.PAUSED;
    string private _baseURL;
    string private _hiddenURI;
    address private immutable _beneficiary;
    mapping(SalesWave => WavePriceLimit) private _wavePrice;
    mapping(SalesWave => string) private _revealURLs;
    //mapping(address => uint) private _mintedCount;

    constructor(string memory hiddenUri_, address beneficiary_) 
    ERC721("DelayedWaves", "DW"){
        _hiddenURI = hiddenUri_;
        _beneficiary = beneficiary_;

        _wavePrice[SalesWave.WAVE1] = WavePriceLimit(WAVE1_PRICE, WAVE1_LIMIT);
        _wavePrice[SalesWave.WAVE2] = WavePriceLimit(WAVE2_PRICE, WAVE2_LIMIT);
        _wavePrice[SalesWave.WAVE3] = WavePriceLimit(WAVE3_PRICE, WAVE3_LIMIT);
    }

    struct WavePriceLimit {
        uint price;
        uint limit;
    }

    /// @notice Reveal metadata per wave
    function reveal(SalesWave wave, string memory uri) external onlyOwner {
        require(wave != SalesWave.PAUSED, "Invalid wave");
        _revealURLs[wave] = uri;
    }

    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }

    function setWave(SalesWave wave) external onlyOwner {
        saleWave = wave;
    }

    /// @notice Withdraw contract's balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(_beneficiary).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _mintTokens(to, count);
    }

    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        SalesWave wave = SalesWave.WAVE1;

        if(tokenId > WAVE1_LIMIT) {
            wave = SalesWave.WAVE2;
        } 
        else if(tokenId > WAVE2_LIMIT) {
            wave = SalesWave.WAVE3;
        }

        string memory revealUrl = _revealURLs[wave];

        return bytes(revealUrl).length > 0
            ? string(abi.encodePacked(revealUrl, tokenId.toString(), ".json"))
            : _hiddenURI;
    }

    
    function mint(uint count) external payable {
        require(saleWave != SalesWave.PAUSED, "ZeroCodeNFT: Sales are off");

        WavePriceLimit memory data = _wavePrice[saleWave];

        require(count <= TOKENS_PER_TRAN_LIMIT, "ZeroCodeNFT: Requested token count exceeds allowance (2)");
        require(_tokenIds.current() + count <= data.limit, "ZeroCodeNFT: Number of requested tokens will exceed limit");
        require(msg.value >= count * data.price, "ZeroCodeNFT: Ether value sent is not sufficient");

        // _mintedCount[msg.sender] += count;
        _mintTokens(msg.sender, count);
    }

    /// @dev Perform actual minting of the tokens
    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index < count; index++) {

            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }

}
