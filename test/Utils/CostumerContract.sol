// SPDX-License-Identifier: UNLICENSED
// (c) SphereX 2023 Terms&Conditions

pragma solidity >=0.6.2;

import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";
import {Proxy} from "openzeppelin/proxy/Proxy.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

import "spherex-protect-contracts/SphereXProtected.sol";
import "spherex-protect-contracts/SphereXProtectedBase.sol";

import {ProtectedUUPSUpgradeable} from "spherex-protect-contracts/ProtectedProxies/ProtectedUUPSUpgradeable.sol";

contract CustomerContractProxy is Proxy {
    bytes32 space; // only so the x variable wont be overriden by the _imp variable
    address private _imp;

    constructor(address implementation) {
        _imp = implementation;
    }

    function _implementation() internal view override returns (address) {
        return _imp;
    }
}

contract SomeContract is SphereXProtectedBase {
    constructor(address admin, address operator, address engine) SphereXProtectedBase(admin, operator, engine) {}

    function someFunc() external sphereXGuardExternal(100) {}
}

contract CustomerBehindProxy {
    function try_allowed_flow() external {}

    function try_blocked_flow() external {}
}

contract CustomerBehindProxy1 {
    function new_func() external {}
}

contract UUPSCustomerUnderProtectedERC1967SubProxy is ProtectedUUPSUpgradeable, CustomerBehindProxy {
    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}

contract UUPSCustomerUnderProtectedERC1967SubProxy1 is ProtectedUUPSUpgradeable, CustomerBehindProxy1 {
    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}

contract UUPSCustomer is UUPSUpgradeable, CustomerBehindProxy {
    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}

contract UUPSCustomer1 is UUPSUpgradeable, CustomerBehindProxy1 {
    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}

contract CostumerContract is SphereXProtected {
    uint256 public slot0 = 5;

    SomeContract internal someContract;

    constructor() SphereXProtected() {}

    function initialize(address owner) public {
        slot0 = 5;
        __SphereXProtectedBase_init(owner, msg.sender, address(0));
    }

    function try_allowed_flow() external sphereXGuardExternal(1) {}

    function try_blocked_flow() external sphereXGuardExternal(2) {}

    function call_inner() external sphereXGuardExternal(3) {
        inner();
    }

    function inner() private sphereXGuardInternal(4) {
        try CostumerContract(address(this)).reverts() {} catch {}
    }

    function reverts() external sphereXGuardExternal(5) {
        require(1 == 2, "revert!");
    }

    function publicFunction() public sphereXGuardPublic(6, this.publicFunction.selector) returns (bool) {
        return true;
    }

    function publicCallsPublic() public sphereXGuardPublic(7, this.publicCallsPublic.selector) returns (bool) {
        return publicFunction();
    }

    function publicCallsSamePublic(bool callInternal)
        public
        sphereXGuardPublic(8, this.publicCallsSamePublic.selector)
        returns (bool)
    {
        if (callInternal) {
            return publicCallsSamePublic(false);
        } else {
            return true;
        }
    }

    function changex() public sphereXGuardPublic(9, this.changex.selector) {
        slot0 = 6;
    }

    function arbitraryCall(address to, bytes calldata data) external sphereXGuardExternal(10) {
        (bool success, bytes memory result) = to.call(data);
        require(success, "arbitrary call reverted");
    }

    function externalCallsExternal() external sphereXGuardExternal(11) returns (bool) {
        return this.externalCallee();
    }

    function externalCallee() external sphereXGuardExternal(12) returns (bool) {
        return true;
    }

    function factory() external sphereXGuardExternal(13) returns (address) {
        someContract = new SomeContract(sphereXAdmin(), sphereXOperator(), sphereXEngine());
        _addAllowedSenderOnChain(address(someContract));
        return address(someContract);
    }
}
