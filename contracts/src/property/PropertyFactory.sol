pragma solidity 0.5.17;

import {UsingConfig} from "contracts/src/common/config/UsingConfig.sol";
import {Property} from "contracts/src/property/Property.sol";
import {IPropertyGroup} from "contracts/interface/IPropertyGroup.sol";
import {IPropertyFactory} from "contracts/interface/IPropertyFactory.sol";
import {IMarket} from "contracts/interface/IMarket.sol";

/**
 * A factory contract that creates a new Property contract.
 */
contract PropertyFactory is UsingConfig, IPropertyFactory {
	event Create(address indexed _from, address _property);
	event ChangeAuthor(
		address indexed _property,
		address _beforeAuthor,
		address _afterAuthor
	);

	/**
	 * Initialize the passed address as AddressConfig address.
	 */
	constructor(address _config) public UsingConfig(_config) {}

	/**
	 * Creates a new Property contract.
	 */
	function create(
		string calldata _name,
		string calldata _symbol,
		address _author
	) external returns (address) {
		return _create(_name, _symbol, _author);
	}

	/**
	 * Creates a new Property contract and authenticate.
	 * There are too many local variables, so when using this method limit the number of arguments that can be used to authenticate to a maximum of 3.
	 */
	function createAndAuthenticate(
		string calldata _name,
		string calldata _symbol,
		address _market,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3
	) external returns (bool) {
		return
			IMarket(_market).authenticateFromPropertyFactory(
				_create(_name, _symbol, msg.sender),
				msg.sender,
				_args1,
				_args2,
				_args3,
				"",
				""
			);
	}

	/**
	 * Creates a new Property contract.
	 */
	function _create(
		string memory _name,
		string memory _symbol,
		address _author
	) private returns (address) {
		/**
		 * Creates a new Property contract.
		 */
		Property property =
			new Property(address(config()), _author, _name, _symbol);

		/**
		 * Adds the new Property contract to the Property address set.
		 */
		IPropertyGroup(config().propertyGroup()).addGroup(address(property));

		emit Create(msg.sender, address(property));
		return address(property);
	}

	function createChangeAuthorEvent(
		address _beforeAuthor,
		address _afterAuthor
	) external {
		require(
			IPropertyGroup(config().propertyGroup()).isGroup(msg.sender),
			"this is illegal address"
		);

		emit ChangeAuthor(msg.sender, _beforeAuthor, _afterAuthor);
	}
}
