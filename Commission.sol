pragma solidity ^0.4.11;

import './Oracled.sol';
import './SafeMath.sol';
import './Referral.sol';
import './BetexToken.sol';

contract Commission is Oracled {
  using SafeMath for uint;

  address betex;
  Referral referral;
  BetexToken token;

  uint referralPercent;
  uint reservePercent;
  uint developmentPercent;
  uint brokerPercent;
  uint holderPercent;

  mapping (address => uint) commissionTokens;
  address[] winnerAddresses;

  event ReferralIncome(address _referral, address _founder, uint _amount, uint _timestamp);

  modifier onlyBetex() {
    if (msg.sender == betex)
      _;
  }

  modifier isWinnerNotExist(address _user) {
    bool isExist = false;
    for (uint i = 0; i < winnerAddresses.length; i++ ) {
      if (winnerAddresses[i] == _user) {
          isExist = true;
          break;
      }
    }

    if (!isExist)
      _;
  }

  function getWinnersAmount() public view returns(uint) {
    return winnerAddresses.length;
  }

  function received(address _user, uint amount) external onlyBetex() {
    commissionTokens[_user] = commissionTokens[_user].add(amount);
    addWinerAddress(_user);
  }

  function payOut(uint _from, uint _to) external onlyOracle() {
    for (uint i = _from; i < _to; i++ ) {
      payOut(winnerAddresses[i]);
    }
  }

  function deleteEmptyUsers(uint _from, uint _to) external onlyOracle() {
    for (uint i = _from; i < _to; i++ ) {
      if (commissionTokens[winnerAddresses[_from]] == 0)
        removeByIndex(_from);
    }
  }

  function payOut(address _user) internal {
    uint balance = commissionTokens[_user];
    if (balance == 0)
      return;

    address _founder = referral.getFounder(_user);
    if (_founder == 0x0)
      _founder = _user;

    uint referralPayment = referralPercent.mul(balance).div(100);
    uint reservePayment = reservePercent.mul(balance).div(100);
    uint developmentPayment = developmentPercent.mul(balance).div(100);
    uint brokerPayment = brokerPercent.mul(balance).div(100);
    uint holderPayment = holderPercent.mul(balance).div(100);

    commissionTokens[_user].sub(referralPayment);
    require(token.transfer(_founder, referralPayment));
    ReferralIncome(_user, _founder, referralPayment, block.timestamp);

    commissionTokens[_user].sub(reservePayment);
    require(token.transfer(contractOwner, reservePayment));

    commissionTokens[_user].sub(developmentPayment);
    require(token.transfer(contractOwner, developmentPayment));

    commissionTokens[_user].sub(brokerPayment);
    require(token.transfer(contractOwner, brokerPayment));

    commissionTokens[_user].sub(holderPayment);
    require(token.transfer(contractOwner, holderPayment));
    //we done all pay outs so we have to clear commissionTokens.
    commissionTokens[_user] = 0;
  }

  function removeByIndex(uint i) internal {
     while ( i < winnerAddresses.length - 1 ) {
       winnerAddresses[i] = winnerAddresses[i + 1];
       i++;
     }
     winnerAddresses.length--;
   }

  function addWinerAddress(address _user) internal isWinnerNotExist(_user) {
    winnerAddresses.push(_user);
  }

  function setBetex(address _betex) onlyContractOwner() {
    betex = _betex;
  }

  function setReferral(address _referral) onlyContractOwner() {
    referral = Referral(_referral);
  }

  function setToken(address _token) onlyContractOwner() {
    token = BetexToken(_token);
  }

  function setReferralPercent(uint _referralPercent) onlyContractOwner() {
    require(_referralPercent > 0 && _referralPercent <= 100);
    referralPercent = _referralPercent;
  }

  function setReservePercent(uint _reservePercent) onlyContractOwner() {
    require(_reservePercent > 0 && _reservePercent <= 100);
    reservePercent = _reservePercent;
  }

  function setDevelopmentPercent(uint _developmentPercent) onlyContractOwner() {
    require(_developmentPercent > 0 && _developmentPercent <= 100);
    developmentPercent = _developmentPercent;
  }

  function setBrokerPercent(uint _brokerPercent) onlyContractOwner() {
    require(_brokerPercent > 0 && _brokerPercent <= 100);
    brokerPercent = _brokerPercent;
  }

  function setHolderPercent(uint _holderPercent) onlyContractOwner() {
    require(_holderPercent > 0 && _holderPercent <= 100);
    holderPercent = _holderPercent;
  }

}
