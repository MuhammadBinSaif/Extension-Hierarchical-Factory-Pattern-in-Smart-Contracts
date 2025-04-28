// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./CityFactory.sol";

//library to split the code from super facotry to reduce bytecode size
library CityLibrary {
    function createCityFactory(address controlAddress) external returns (address) {
        return address(new CityFactory(controlAddress));
    }
}