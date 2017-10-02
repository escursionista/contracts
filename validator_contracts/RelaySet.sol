pragma solidity ^0.4.15;

import "./Owned.sol";
import "./ValidatorSet.sol";

contract OuterSet is Owned, ValidatorSet {
	// System address, used by the block sealer.
	address constant SYSTEM_ADDRESS = 0xfffffffffffffffffffffffffffffffffffffffe;
	bytes4 SIGNATURE = 0xb7ab4db5;

	modifier only_system_and_not_finalized() {
		require(msg.sender == SYSTEM_ADDRESS && !finalized);
		_;
	}

	modifier only_inner_and_finalized() {
		require(msg.sender == address(innerSet) && finalized);
		_;
	}

	InnerSet public innerSet;
	// Was the last validator change finalized.
	bool public finalized;

	function setInner(address _inner) public only_owner {
		innerSet = InnerSet(_inner);
	}

	// For innerSet.
	function initiateChange(bytes32 _parent_hash, address[] _new_set) public only_inner_and_finalized {
		finalized = false;
		InitiateChange(_parent_hash, _new_set);
	}

	// For sealer.
	function finalizeChange() public only_system_and_not_finalized {
		finalized = true;
		innerSet.finalizeChange();
	}

	function getValidators() public constant returns (address[]) {
		address addr = innerSet;
		bytes4 sig = SIGNATURE;
		assembly {
			mstore(0, sig)
			let ret := call(0xfffffffface8, addr, 0, 0, 4, 0, 0)
			jumpi(0x02,iszero(ret))
			returndatacopy(0, 0, returndatasize)
			return(0, returndatasize)
		}
	}
}

contract InnerSet {
	OuterSet public outerSet;

	function getValidators() public constant returns (address[]);
	function finalizeChange() public;
}
