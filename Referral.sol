pragma solidity ^0.4.11;

contract Referral {
  mapping (address => address) referralFounder;

  event ReferralAdded(address _founder, address _referral, uint _timestamp);

  function getFounder(address _referral) view returns(address) {
    return referralFounder[_referral];
  }

  function setFounder(address _founder) external {
    require(referralFounder[msg.sender] == 0x0);
    referralFounder[msg.sender] = _founder;
    ReferralAdded(_founder, msg.sender, block.timestamp);
  }
}
