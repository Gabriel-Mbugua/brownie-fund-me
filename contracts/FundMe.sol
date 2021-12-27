// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "smartcontractkit/chainlink-brownie-contracts@1.1.1/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "smartcontractkit/chainlink-brownie-contracts@1.1.1/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // prevents overflow from occuring
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // initialise owner immediately contract is created
    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        // create minimum value and convert it to wei
        uint256 minimumUSD = 50 * 10**18;
        // make sure minimum amount is meet
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10_000_000_000);
        //4586.58324263
    }

    // convert wei to usd (1 gwei = 10000000000 wei)
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        // require msg.sender = owner of contract
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimum USD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    // will check the above modifier and only run the code if it receives _
    function withdraw() public payable onlyOwner {
        // transfer all funds from the address in this contract
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
