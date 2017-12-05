pragma solidity ^0.4.11;


import './BasicToken.sol';
import './ERC20.sol';
import './Oracled.sol';


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract BetexToken is ERC20, BasicToken, Oracled {

  mapping (address => mapping (address => uint256)) internal allowed;

  address betex;
  address exchange;
  address owner;
  string public name = "Stable Betex Token";
  string public symbol = "SBT";
  uint public decimals = 18;

  event Minting(address indexed to, uint256 value);
  event Burned(address indexed from, uint256 value);

  modifier onlyBetex() {
    if (msg.sender == betex)
      _;
  }

  modifier onlyExchange() {
    if (msg.sender == exchange)
      _;
  }

  function BetexToken() {
    owner = msg.sender;
    totalSupply = 0;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function _transfer(address _from, address _to, uint _value) internal returns (bool) {
    require (_to != address(0));
    require (balances[_from] >= _value);
    require (balances[_to] + _value >= balances[_to]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function setBetex(address _betex) onlyContractOwner() {
    require(betex==address(0));
    betex = _betex;
  }

  function setExchange(address _exchange) onlyContractOwner() {
    require(exchange == address(0));
    exchange = _exchange;
  }

  function transferToBetex(address _from, uint256 _value) onlyBetex() public returns (bool) {
    return _transfer(_from, betex, _value);
  }

  function transferFromBetex(address _to, uint256 _value) onlyBetex() public returns (bool) {
    return _transfer(betex, _to, _value);
  }

  function minting(address _to, uint256 _value) onlyExchange() public returns (bool) {
    require (balances[_to] + _value >= balances[_to]);

    totalSupply += _value;
    balances[_to] = balances[_to].add(_value);

    Minting(_to, _value);

    return true;
  }

  function burned(address _from, uint256 _value) onlyExchange() public returns (bool) {
    require (balances[_from] >= _value);

    totalSupply -= _value;
    balances[_from] = balances[_from].sub(_value);

    Burned(_from, _value);

    return true;
  }

  function getOwner() returns (address){
    return owner;
  }

}
