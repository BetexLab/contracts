pragma solidity ^0.4.10;

import './Owned.sol';

contract Oracled is Owned {
  address oracleAddress;

  function Oracled() {
    oracleAddress = msg.sender;
  }

  modifier onlyOracle() {
    if (oracleAddress == msg.sender)
      _;
  }

  function changeOracledAddress(address _to) onlyContractOwner() returns(bool) {
    oracleAddress = _to;
    return true;
  }

}
