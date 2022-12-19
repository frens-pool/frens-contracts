// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./interfaces/ISSVRegistry.sol";
import "./interfaces/IFrensMetaHelper.sol";
import "./FrensBase.sol";
import './ToColor.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract FrensMetaHelper is IFrensMetaHelper, FrensBase {

  using ToColor for bytes3;
  using Strings for uint256;

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage) {
    //hi fren
  }

  function getColor(address a) public pure returns(string memory){
    bytes32 colorRandomness = keccak256(abi.encodePacked(address(a)));
    bytes3 colorBytes = bytes2(colorRandomness[0]) | ( bytes2(colorRandomness[1]) >> 8 ) | ( bytes3(colorRandomness[2]) >> 16 );
    string memory color = colorBytes.toColor();
    return color;
  }

  function getEthDecimalString(uint amountInWei) public pure returns(string memory){
    string memory leftOfDecimal = (amountInWei / 1 ether).toString();
    uint rightOfDecimal = (amountInWei % 1 ether) / 10**14;
    string memory rod = rightOfDecimal.toString();
    if(rightOfDecimal < 1000) rod = string.concat("0", rod);
    if(rightOfDecimal < 100) rod = string.concat("0", rod);
    if(rightOfDecimal < 10) rod = string.concat("0", rod);
    return string.concat(leftOfDecimal, ".", rod);
  }

  function getOperatorsForPool(address poolAddress) public view returns (uint32[] memory, string memory) {
    bytes memory poolPubKey = getBytes(keccak256(abi.encodePacked("validator.public.key", poolAddress)));
    string memory pubKeyString = _iToHex(poolPubKey);
    ISSVRegistry ssvRegistry = ISSVRegistry(getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVRegistry"))));
    uint32[] memory poolOperators = ssvRegistry.getOperatorsByValidator(poolPubKey);
    return(poolOperators, pubKeyString);
  }

  function _iToHex(bytes memory buffer) internal pure returns (string memory) {
      // Fixed buffer size for hexadecimal convertion
      bytes memory converted = new bytes(buffer.length * 2);
      bytes memory _base = "0123456789abcdef";
      for (uint256 i = 0; i < buffer.length; i++) {
          converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
          converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
      }
      return string(abi.encodePacked("0x", converted));
  }
}
