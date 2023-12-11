// SPDX-License-Identifier: UNLICENSED
// (c) SphereX 2023 Terms&Conditions

pragma solidity ^0.8.0;

import {Proxy} from "openzeppelin/proxy/Proxy.sol";
import {Address} from "openzeppelin/utils/Address.sol";

import {SphereXProxyBase} from "./SphereXProxyBase.sol";
import {ModifierLocals} from "./ISphereXEngine.sol";

/**
 * @title SphereX abstract proxt contract which implements OZ's Proxy intereface.
 */
abstract contract SphereXProtectedProxy is SphereXProxyBase, Proxy {
    constructor(address admin, address operator, address engine) SphereXProxyBase(admin, operator, engine) {}

    /**
     * The main point of the contract, wrap the delegate operation with SphereX's protection modfifier
     * @param implementation delegate dst
     */
    function _protectedDelegate(address implementation) private returns (bytes memory ret) {
        ModifierLocals memory locals = _sphereXValidatePre(int256(uint256(uint32(msg.sig))), true);
        ret = Address.functionDelegateCall(implementation, msg.data);
        _sphereXValidatePost(-int256(uint256(uint32(msg.sig))), true, locals, ret);
        return ret;
    }

    /**
     * Override Proxy.sol _delegate to make every inheriting proxy delegate with sphere'x protection
     * @param implementation delegate dst
     */
    function _delegate(address implementation) internal virtual override {
        if (isProtectedFuncSig(msg.sig)) {
            bytes memory ret_data = _protectedDelegate(implementation);
            uint256 ret_size = ret_data.length;

            assembly {
                return(add(ret_data, 0x20), ret_size)
            }
        } else {
            super._delegate(implementation);
        }
    }
}
