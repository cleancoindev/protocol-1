pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./libs/Utils.sol";
import "./UseState.sol";
import "./policy/PolicyFactory.sol";

contract Lockup is UseState {
	using SafeMath for uint256;
	TokenValue private tokenValue;
	CanceledLockupFlg private canceledFlg;
	ReleasedBlockNumber private releasedBlockNumber;

	constructor() public {
		tokenValue = new TokenValue();
		canceledFlg = new CanceledLockupFlg();
		releasedBlockNumber = new ReleasedBlockNumber();
	}

	function lockup(address propertyAddress, uint256 value) public {
		require(
			canceledFlg.isCanceled(msg.sender, propertyAddress) == false,
			"lock up is already canceled"
		);
		ERC20 devToken = ERC20(getToken());
		uint256 balance = devToken.balanceOf(msg.sender);
		require(value <= balance, "insufficient balance");
		// solium-disable-next-line security/no-low-level-calls
		(bool success, bytes memory data) = address(devToken).delegatecall(
			abi.encodeWithSignature(
				"transfer(address,uint256)",
				propertyAddress,
				value
			)
		);
		require(success, "transfer was failed.");
		require(abi.decode(data, (bool)), "transfer was failed.");
		tokenValue.set(msg.sender, propertyAddress, value);
	}

	function cancel(address propertyAddress) public {
		require(
			tokenValue.hasTokenByProperty(msg.sender, propertyAddress),
			"dev token is not locked"
		);
		require(
			canceledFlg.isCanceled(msg.sender, propertyAddress) == false,
			"lock up is already canceled"
		);
		// TODO after withdrawal, allow the flag to be set again
		// TODO after withdrawal, update locked up value
		canceledFlg.setCancelFlg(msg.sender, propertyAddress);
		releasedBlockNumber.setBlockNumber(
			msg.sender,
			propertyAddress,
			Policy(policy()).lockUpBlocks()
		);
	}

	function getTokenValue(address fromAddress, address propertyAddress)
		public
		view
		returns (uint256)
	{
		return tokenValue.get(fromAddress, propertyAddress);
	}
}

contract TokenValue {
	using SafeMath for uint256;
	mapping(address => mapping(address => uint256)) private _lockupedTokenValue;
	function set(address fromAddress, address propertyAddress, uint256 value)
		public
	{
		_lockupedTokenValue[fromAddress][propertyAddress] += value;
	}

	function hasTokenByProperty(address fromAddress, address propertyAddress)
		public
		view
		returns (bool)
	{
		return _lockupedTokenValue[fromAddress][propertyAddress] != 0;
	}

	function get(address fromAddress, address propertyAddress)
		public
		view
		returns (uint256)
	{
		return _lockupedTokenValue[fromAddress][propertyAddress];
	}
}

contract CanceledLockupFlg {
	mapping(address => mapping(address => bool)) private _canceled;
	function setCancelFlg(address fromAddress, address propertyAddress) public {
		_canceled[fromAddress][propertyAddress] = true;
	}
	function isCanceled(address fromAddress, address propertyAddress)
		public
		view
		returns (bool)
	{
		return _canceled[fromAddress][propertyAddress];
	}
}

contract ReleasedBlockNumber {
	using SafeMath for uint256;
	mapping(address => mapping(address => uint256)) private _released;
	function setBlockNumber(
		address fromAddress,
		address propertyAddress,
		uint256 wait
	) public {
		_released[fromAddress][propertyAddress] = block.number + wait;
	}
}
