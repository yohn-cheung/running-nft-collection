// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract RunningDevs is ERC721Enumerable, Ownable {
    string _baseTokenURI;

    // price for one Running Devs NFT
    uint256 public _price = 0.01 ether;

    bool public _paused;

    uint256 public maxTokenIds = 50;

    // total number of tokenIds minted
    uint256 public tokenIds;

    IWhitelist whitelist;

    bool public presaleStarted;

    uint256 public presaleEnded;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }

    /**
     * @dev ERC721 constructor takes in a `name` and a `symbol` to the token collection.
     * name in our case is `Crypto Devs` and symbol is `CD`.
     * Constructor for Crypto Devs takes in the baseURI to set _baseTokenURI for the collection.
     * It also initializes an instance of whitelist interface.
     */

    constructor(string memory baseURI, address whitelistContract)
        ERC721("Running Devs Club", "RDC")
    {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

		/**
      * @dev startPresale starts a presale for the whitelisted addresses
       */
    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 10 minutes;
    }

		/**
       * @dev presaleMint allows a user to mint one NFT per transaction during the presale.
       */

		function presaleMint() public payable onlyWhenNotPaused {
			require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
			require(whitelist.whitelistedAddresses(msg.sender), "You are not on the whitelist");
			require(tokenIds < maxTokenIds, "Exceeded maximum Running Devs supply");
			require(msg.value >= _price, "Ether is not sufficient");

			tokenIds +=1;
			_safeMint(msg.sender, tokenIds);
		}

		 /**
      * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
      * returned an empty string for the baseURI
      */

		function _baseURI() internal view virtual override returns (string memory) {
			return _baseTokenURI;
		}

		function setPaused(bool val) public onlyOwner {
			_paused = val;
		}

		function withdraw() public onlyOwner  {
    	address _owner = owner();
      uint256 amount = address(this).balance;
      (bool sent, ) =  _owner.call{value: amount}("");
      require(sent, "Failed to send Ether");
    }

		// Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
  }
}
