pragma solidity 0.4.18;
import "./ERC677.sol";
import "./SafeMath.sol";

contract IGVToken is ERC677Token, SafeMath {

    // metadata
    string public constant name = "I Gave Token";
    string public constant symbol = "IGV";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    address public ethReceiver;  // Where the Eth goes after the ICO
    address public devReceiver;  // Who controls the dev fund after the ICO

    // crowdsale parameters
    bool public fundOver;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    // 10,000 IGV tokens per 1 ETH
    uint256 public constant tokenExchangeRate = 10000;
    uint256 public constant devExchangeRate = 2500;
    uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  25 * (10**5) * 10**decimals;

    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateIGV(address indexed _to, uint256 _value);

    // constructor
    function IGVToken(
        address _ethReceiver,
        address _devReceiver,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      fundOver = false;

      ethReceiver = _ethReceiver;
      devReceiver = _devReceiver;

      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
    }

    function createTokens() payable external {
      if (fundOver ||
          block.number < fundingStartBlock ||
          block.number > fundingEndBlock ||
          msg.value == 0) {
            revert();
          }

      uint256 tokens = safeMult(msg.value, tokenExchangeRate);
      uint256 devTokens = safeMult(msg.value, devExchangeRate);
      uint256 totalTokens = safeAdd(tokens, devTokens);
      uint256 checkedSupply = safeAdd(totalSupply, totalTokens);

      if (tokenCreationCap < checkedSupply) {
        revert();
      }

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;
      balances[devReceiver] += devTokens;
      CreateIGV(msg.sender, tokens);
    }

    function finalize() external {
      if (fundOver ||
          msg.sender != ethReceiver ||
          totalSupply < tokenCreationMin ||
          block.number <= fundingEndBlock && totalSupply != tokenCreationCap) {
            revert();
          }

      fundOver = true;
      if(!ethReceiver.send(this.balance)) {
        revert();
      }
    }

    /// Allows withdrawal if crowdfund fails
    function refund() external {
      if(fundOver ||
         block.number <= fundingEndBlock ||
         totalSupply >= tokenCreationMin ||
         msg.sender == devReceiver) {
           revert();
        }

      uint256 igvTotal = balances[msg.sender];
      if (igvTotal == 0) {
        revert();
      }

      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, igvTotal);

      uint256 ethTotal = igvTotal / tokenExchangeRate;
      LogRefund(msg.sender, ethTotal);
      if (!msg.sender.send(ethTotal)) {
        revert();
      }
    }

}