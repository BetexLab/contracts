pragma solidity ^0.4.13;

import "./BetexToken.sol";
import "./Oracled.sol";
import './SafeMath.sol';

contract BetexExchange is Oracled {
  using SafeMath for uint;

  address oracleAddress;
  BetexToken token;
  uint public buyPrice;

  event Buy(address userAddress, uint amount, uint _buyPrice, uint timestamp);
  event Sell(address userAddress, uint amount, uint _buyPrice, uint timestamp);

  function BetexExchange(address _tokenContractAddress, uint _buyPrice) {
    buyPrice = _buyPrice;
    oracleAddress = msg.sender;
    token = BetexToken(_tokenContractAddress);
  }

  function () payable {
      uint amount = msg.value.mul(buyPrice);
      require(amount > 0);
      require(token.minting(msg.sender, amount));

      Buy(msg.sender, amount, buyPrice, block.timestamp);
  }

  function sellTokens(uint _value) {
    require(token.burned(msg.sender, _value));
    uint _wei = _value / buyPrice;

    require(_wei > 0);
    require(msg.sender.send(_wei));

    Sell(msg.sender, _value, buyPrice, block.timestamp);
  }

  function updateRateData(uint _buyPrice) public onlyOracle() {
    buyPrice = _buyPrice;
  }

}
