// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts@v4.9.3/token/ERC721/ERC721.sol";

import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

// Simple contract which allows users to create NFTs with attached streams

contract SoMenTake is ERC721{
    using SuperTokenV1Library for ISuperToken;

    int96 portion = 1e16;

    string public IPFSuri = "ipfs://bafkreidcohfhme3oqc2lbstareydnu2p2j7adiandbrcjfydmrr2n6fw4u";
    uint256 immutable tokenStartPrice;
    uint256 public totalSupply; // this is so we can increment the number

    ISuperToken public immutable somen;
    address public immutable owner;

    constructor(
            ISuperToken token,
            uint256 _tokenStartPrice
        ) 
        // hardcoding to make testing faster
        ERC721(
            unicode'"So麺の竹"',//_name,
            unicode'"竹"'//_symbol
            ) {
        somen = token; 
        owner = msg.sender; 
        tokenStartPrice = _tokenStartPrice;
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return IPFSuri;
    }

    /**
     * @dev Internal function that returns the current price
     */
    function tokenPrice() public view returns (uint256) {
        return (tokenStartPrice * (100 + totalSupply)) / 100;
    }

    /**
     * @dev Public function that mints a NFT for the given address
     * and starts the stream
     */

    function mint() external payable {
        require(msg.value >= tokenPrice(), "SOUMEN: okane tarinakatta!");
        // mint should also take care of giving the user a unit
        _mint(msg.sender, totalSupply);
        totalSupply++;
        payable(owner).transfer(msg.value);
    }

    //now I will insert a hook in the _transfer, executing every time the token is moved
    //When the token is first "issued", i.e. moved from the first contract, it will start the stream 
    function _beforeTokenTransfer(
        address oldReceiver,
        address newReceiver,
        uint256 /*tokenId*/,
        uint256 /*batchSize*/
    ) internal override {
            require(newReceiver != address(0), "New receiver is zero address");
            int96 flowrate = somen.getFlowRate(address(this), newReceiver); 
            require(flowrate == 0, "SOUMEN: don't be greedy!");

            // @dev delete flow to old receiver
            if(oldReceiver != address(0)) somen.deleteFlow(address(this), oldReceiver);           
            somen.createFlow(newReceiver, portion);
      }
}
