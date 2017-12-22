pragma solidity 0.4.18;
import "./ERC721.sol";
import "./SafeMath.sol";

contract IGVToken is ERC721 {
  function implementsERC721() public pure returns (bool)
  {
      return true;
  }
}
