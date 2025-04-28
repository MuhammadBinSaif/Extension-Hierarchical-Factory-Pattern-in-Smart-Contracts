// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./StationContract.sol";

//library to split the code from super facotry to reduce bytecode size
library StationLibrary{
    function createStationContract(address controlAddress) external returns (address) {
        return address(new StationContract(controlAddress));
    }
}
