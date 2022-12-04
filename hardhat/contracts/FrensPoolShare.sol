// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/ISSVRegistry.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './ToColor.sol';


contract FrensPoolShare is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using ToColor for bytes3;

  uint private _tokenId;
  mapping(uint => address) poolById;

  IStakingPoolFactory factoryContract;
  ISSVRegistry ssvRegistry;

  constructor(address factoryAddress_, address ssvRegistryAddress_) ERC721("staking con amigos", "FRENS") {
    factoryContract = IStakingPoolFactory(factoryAddress_);
    ssvRegistry = ISSVRegistry(ssvRegistryAddress_);
  }

  modifier onlyStakingPools(address _stakingPoolAddress) {
    require(factoryContract.doesStakingPoolExist(_stakingPoolAddress), "must be a staking pool");
    _;
  }

  function incrementTokenId() public onlyStakingPools(msg.sender) returns(uint){
    _tokenId++;
    return _tokenId;
  }

  function mint(address userAddress, uint id, address _pool) public onlyStakingPools(msg.sender) {
    poolById[id] = _pool;
    _safeMint(userAddress,id);
  }

  function exists(uint _id) public view returns(bool){
    return _exists(_id);
  }

  function getPoolById(uint _id) public view returns(address){
    return poolById[_id];
  }

  //art stuff


  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    address poolAddress = poolById[id];
    IStakingPool stakingPool = IStakingPool(payable(poolAddress));
    uint depositForId = stakingPool.getDepositAmount(id);
    string memory depositString = getEthDecimalString(depositForId);
    uint shareForId = stakingPool.getDistributableShare(id);
    string memory shareString = getEthDecimalString(shareForId);
    string memory stakingPoolAddress = Strings.toHexString(uint160(poolAddress), 20);
    (uint32[] memory poolOperators, string memory pubKeyString) = getOperatorsForPool(poolAddress);
    string memory poolState = stakingPool.getState();
    string memory name = string(abi.encodePacked('fren pool share #',id.toString()));
    string memory description = string(abi.encodePacked(
      'this fren has a deposit of ',depositString,
      ' Eth in pool ', stakingPoolAddress,
      ', with claimable balance of ', shareString, ' Eth'));
    string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));


//TODO: add pool owner to traits and possibly art (Add ENS integration for art - only display if ENS exists for address)
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                name,
                '", "description":"',
                description,
                '", "external_url":"https://frens.fun/token/',
                id.toString(),
                '", "attributes": [{"trait_type": "pool", "value":"',
                stakingPoolAddress,
                '"},{"trait_type": "validator public key", "value": "',
                pubKeyString,
                '"},{"trait_type": "deposit", "value": "',
                depositString, ' Eth',
                '"},{"trait_type": "claimable", "value": "',
                shareString, ' Eth',
                '"},{"trait_type": "pool state", "value": "',
                poolState,
                '"},{"trait_type": "operator1", "value": "',
                poolOperators.length == 0 ? "Not Set" : uint2str(poolOperators[0]),
                '"},{"trait_type": "operator2", "value": "',
                poolOperators.length == 0 ? "Not Set" : uint2str(poolOperators[1]),
                '"},{"trait_type": "operator3", "value": "',
                poolOperators.length == 0 ? "Not Set" : uint2str(poolOperators[2]),
                '"},{"trait_type": "operator4", "value": "',
                poolOperators.length == 0 ? "Not Set" : uint2str(poolOperators[3]),
                '"}], "image": "',
                'data:image/svg+xml;base64,',
                image,
                '"}'
              )
            )
          )
        )
      );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  function getColor(address a) internal pure returns(string memory){
    bytes32 colorRandomness = keccak256(abi.encodePacked(address(a)));
    bytes3 colorBytes = bytes2(colorRandomness[0]) | ( bytes2(colorRandomness[1]) >> 8 ) | ( bytes3(colorRandomness[2]) >> 16 );
    string memory color = colorBytes.toColor();
    return color;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {

    IStakingPool stakingPool = IStakingPool(payable(poolById[id]));
    uint depositForId = stakingPool.getDepositAmount(id);
    string memory depositString = getEthDecimalString(depositForId);
    uint shareForId = stakingPool.getDistributableShare(id);
    string memory shareString = getEthDecimalString(shareForId);
    string memory poolColor = getColor(address(stakingPool));
    string memory textColor = getColor(ownerOf(id));

    string memory render = string(abi.encodePacked(

      //"frens" lettering stlying
      '<defs><style>@font-face{font-family:"Permanent Marker";src:url(data:application/font-woff;charset=utf-8;base64,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) format("woff"); font-weight:normal;font-style:normal;}</style></defs>'

      '<circle cx="200" cy="200" r="170" fill="#',
        poolColor,
      '"/>,'
      //shaka
      '<g transform="matrix(.707107 -.70710678 .70710678 .707107 16 153)" stroke="none" fill-rule="nonzero"><path d="M196.2512 233.555c8.3009 0 9.8263-6.9913 8.1372-12.24-1.6351-5.0915-6.5388-9.2041-16.1456-13.4342-18.6514-8.1867-44.9124-15.3737-44.9124-17.8813s11.2595-.665 25.952-3.4659c11.1504-2.1342 12.204-6.4434 13.6215-13.9247 1.6891-8.8516-4.0689-15.5493-4.0689-15.5493s9.8988-3.9178 9.8988-16.099-11.4057-17.6453-11.4057-17.6453 4.6668-3.0747 5.866-10.2425c1.4894-8.8319-4.4865-16.6662-12.6045-22.5219-6.8467-4.9352-15.5279-9.3614-21.9741-12.0446-5.5393-2.3102-9.6994-3.936-23.3019-3.7602-10.9517.1372-16.3081-.2153-17.144-3.9951-.6356-2.8202 1.6347-5.7382 3.904-12.8275 2.8157-8.7339 10.0441-31.256-3.0874-51.3503-5.0481-7.7155-18.1245-7.598-20.7756-4.9148-5.0497 5.1108 1.5253 15.3338-1.98 33.645-2.4151 12.6321-5.3214 21.249-17.2164 30.9824-6.8661 5.6207-22.0854 14.963-33.8356 30.6297-4.3587 5.7979-17.9428 4.7004-25.5348 3.5652-3.032-.4507-5.8841 1.7227-6.4831 4.9739-6.0301 32.3922-1.9433 66.2534.0905 79.3165.4911 3.1726 3.1423 5.4245 6.1208 5.1895 6.7737-.5086 18.2526-1.2925 21.8119-.8611 7.1738.8611 21.9389 12.4552 42.1698 18.6239 17.9615 5.4838 43.5155 10.5559 54.9387 11.2413s59.8411 14.5903 67.9588 14.5903z" fill="#ffca28"/><path d="M131.2159 74.786v.3141c6.9566.0192 13.2219 7.0502 12.9677 14.5512-.31 8.7336-11.6234 12.3186-7.3188 24.6756.8706 2.5251 11.4597 6.6976 8.8616 19.2512-2.1244 10.2827-10.0614 9.5562-10.0614 14.7071 0 8.7359 9.4624 14.5704 10.1345 24.5197s-4.0677 11.5345-3.7421 14.9828c.2368 2.5466 1.2729 3.4652 1.2729 2.1941 0-2.5082 11.2594-.6666 25.951-3.4675 11.1514-2.1342 12.2049-6.4434 13.6224-13.9252 1.6891-8.8511-4.0695-15.5488-4.0695-15.5488s9.8995-3.9183 9.8995-16.0979-11.4057-17.6469-11.4057-17.6469 4.6667-3.0743 5.8647-10.242c1.4906-8.8319-4.4856-16.6662-12.6037-22.5221-6.8469-4.9351-15.5274-9.3618-21.9737-12.0429-4.632-1.94-8.3376-3.3884-17.3994-3.7025z" fill="#ffb300"/><path d="M135.3022 150.9304c-.1636-4.1328.091-5.2682 2.1071-5.8173s5.7028.9998 5.7028.9998c14.8553-1.3524 30.8928 2.0552 35.7408 10.9277 0 0-23.609-1.8607-32.4723-1.3523-6.9549.4122-10.8781.4892-11.0784-4.7579zm42.0433-27.6145c-14.5104-5.4647-31.4737-6.4432-36.486-6.4432-7.1193 0-5.7568-11.6727-2.7244-13.8658 2.0889-.9203 4.5581 2.3106 6.5015 3.0748 5.7759 2.2908 30.1841 3.7407 32.7089 17.2342zm.9263 109.5939c-26.6423-5.0914-62.148-15.1978-90.3348-19.1146-20.7393-2.878-32.3452-11.5346-41.0801-16.392-4.9223-2.7417-8.8089-4.9147-12.713-5.9722-10.3344-2.8205-18.2891-1.2347-24.7356-1.489s7.7542-10.0275 26.4972-6.0523c4.758.9998 9.1353 3.7409 14.2568 6.5999 8.8262 4.9161 19.6143 12.241 39.3193 15.7064 11.0417 1.9591 27.8048 3.9566 43.5505 8.2251 12.4227 3.35 46.9653 15.2178 58.9874 16.8051 6.1574.8227 11.587-.9805 11.606-.9805 0 0-1.0361 2.6641-5.2309 4.0149-4.4679 1.45-9.7167.6467-20.1228-1.3508zm-62.0753-158.301c-3.7771.5875-11.986-2.0552-8.5724-10.947 5.8122-15.1194 6.2843-20.3472 6.0476-35.5457-.1812-10.8894-3.3052-18.2322-5.6474-22.6781 0 0 18.8516 13.7094 9.3162 56.5404-1.3982 6.2276-1.144 12.6304-1.144 12.6304zm61.0586 109.1441s-4.2854 2.8393-10.0614 5.0142c-5.7934 2.1727-15.4195 3.9951-19.233 4.0143s-8.355-4.3284-5.0847-5.9542c3.2511-1.6044 34.3791-3.0743 34.3791-3.0743z" fill="#eda600"/></g>',
      //ethlogo (partial)
      '<polygon points="200,359 80,220 98,195 200,256" fill="#',
        poolColor,
      '"/>',
      '<polygon points="200,359 98,215 200,276" fill="#8c8c8c" />',
      '<polygon points="200,359 302,215 200,276" fill="#3c3c3b" />',
      //frens text
      '<text font-size="122" x="5" y="240" font-family="Permanent Marker"  opacity=".4" fill="#',
        textColor,
      '">FRENS</text>',
      //frens Text outline
      '<text font-size="122" x="5" y="240" font-family="Permanent Marker" fill="none"  stroke-width="2" stroke="#',
        textColor,
      '">FRENS</text>'
      //deposit text
      '<text font-size="50" text-anchor="middle" x="200" y="135" fill="#FF69B4" stroke="#00EDF5" font-weight="Bold" font-family="Sans-Serif" opacity=".8">',
        depositString, ' Eth',
      '</text>',
      //claimable text
      '<text font-size="25" text-anchor="middle" x="200" y="300" fill="#FF69B4" stroke="#00EDF5" font-weight="Bold" font-family="Sans-Serif" >',
        shareString, ' Eth Claimable',
      '</text>'


      ));

    return render;
  }


  function getEthDecimalString(uint amountInWei) public pure returns(string memory){
    string memory leftOfDecimal = uint2str(amountInWei / 1 ether);
    uint rightOfDecimal = (amountInWei % 1 ether) / 10**14;
    string memory rod = uint2str(rightOfDecimal);
    if(rightOfDecimal < 1000) rod = string.concat("0", rod);
    if(rightOfDecimal < 100) rod = string.concat("0", rod);
    if(rightOfDecimal < 10) rod = string.concat("0", rod);
    return string.concat(leftOfDecimal, ".", rod);
  }

  function getOperatorsForPool(address poolAddress) public view returns (uint32[] memory, string memory) {
    IStakingPool stakingPool = IStakingPool(payable(poolAddress));
    bytes memory poolPubKey = stakingPool.getPubKey();
    string memory pubKeyString = iToHex(poolPubKey);
    uint32[] memory poolOperators = ssvRegistry.getOperatorsByValidator(poolPubKey);
    return(poolOperators, pubKeyString);
  }

  function iToHex(bytes memory buffer) public pure returns (string memory) {
      // Fixed buffer size for hexadecimal convertion
      bytes memory converted = new bytes(buffer.length * 2);
      bytes memory _base = "0123456789abcdef";
      for (uint256 i = 0; i < buffer.length; i++) {
          converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
          converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
      }
      return string(abi.encodePacked("0x", converted));
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
