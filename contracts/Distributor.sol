pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./modules/oraclizeAPI_0.5.sol";
import "./libs/Killable.sol";
import "./UseState.sol";
import "./Repository.sol";

contract Distributor is Killable, usingOraclize, UseState {
	using SafeMath for uint;
	struct Package {
		uint point;
		uint downloads;
		uint balance;
	}

	uint public total = 0;
	Package[] public packages;

	constructor(string memory start, string memory end, uint value) public {
		distribute(start, end, value);
		kill();
	}

	function distribute(string memory start, string memory end, uint value)
		private
	{
		address token = getToken();
		address[] memory repositories = getRepositories();
		for (uint i = 0; i < repositories.length; i++) {
			address repository = repositories[i];
			uint balance = getTotalBalance(repository);
			uint downloads = getNpmDownloads(
				start,
				end,
				Repository(repository).getPackage()
			);
			uint point = balance.add(downloads);
			total = total.add(point);
			packages.push(Package(point, downloads, balance));
		}
		for (uint i = 0; i < repositories.length; i++) {
			address repository = repositories[i];
			uint point = packages[i].point;
			uint per = point.div(total);
			uint count = value.mul(per);
			ERC20Mintable(token).mint(repository, count);
		}
	}

	function getNpmDownloads(
		string memory start,
		string memory end,
		string memory package
	) private returns (uint) {
		string memory url = string(
			abi.encodePacked(
				"https://api.npmjs.org/downloads/point/",
				start,
				":",
				end,
				"/",
				package
			)
		);
		oraclize_query("URL", url);
	}
}
