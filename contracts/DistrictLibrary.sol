// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./DistrictFactory.sol";

//library to split the code from super facotry to reduce bytecode size
library DistrictLibrary{
    function createDistrictFactory(address controlAddress) external returns (address) {
        return address(new DistrictFactory(controlAddress));
    }
}
