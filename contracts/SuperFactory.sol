// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlManager.sol";
import "./CityLibrary.sol";
import "./DistrictLibrary.sol";
import "./StationLibrary.sol";

// Custom error to save gas on revert.


contract SuperFactory {
    // Marking the access control instance immutable (set once in constructor).
    AccessControlManager public immutable accessControlManager;

    // Constructor receives the access control manager address.
    constructor(address _accesscontroladdress) {
        accessControlManager = AccessControlManager(_accesscontroladdress);
    }

    // Modifier checks that the caller holds the ADMIN_ROLE.
    modifier checkAdmin() {
        if (!accessControlManager.hasRole(accessControlManager.ADMIN_ROLE(), msg.sender))
            revert NotAuthorized();
        _;
    }

    // Creates client contracts based on _contract_type.
    // Uses custom error for admin check and an efficient if/else chain.
    function createClientContracts(
        address _client_owner_address,
        address _parent_address,
        bytes32 _owner_name,
        bytes32 _name,
        bytes32 _parent_name,
        bytes32 _data,
        bytes calldata _signature,
        uint _contract_type
    ) external checkAdmin {
        address contractAddress;
        if (_contract_type == 2) {
            contractAddress = CityLibrary.createCityFactory(address(accessControlManager));
        } else if (_contract_type == 3) {
            contractAddress = DistrictLibrary.createDistrictFactory(address(accessControlManager));
        } else {
            contractAddress = StationLibrary.createStationContract(address(accessControlManager));
        }
        // Call the AccessControlManager's function to register the new contract on behalf of a client.
        accessControlManager.addContractOnBehalfOfManager(
            contractAddress,
            _client_owner_address,
            _parent_address,
            _owner_name,
            _name,
            _parent_name,
            _data,
            _signature,
            AccessControlManager.ContractType(_contract_type)
        );
    }
}
