// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlManager.sol";
import "./StationContract.sol";

// Custom error to save gas on reverts.


contract DistrictFactory {
    // Immutable instance to save gas on repeated SLOADs.
    AccessControlManager private immutable accessControlManager;

    // Mapping from a date (uint32, e.g., YYYYMMDD) to an IPFS CID (bytes32 digest).
    mapping(uint32 => bytes32) private ipfsCIDs;
    
    // Constructor sets the AccessControlManager address.
    constructor(address _access_control_address) {
        accessControlManager = AccessControlManager(_access_control_address);
    }

    // Modifier: only accounts with WATER_MANAGER_ROLE are allowed.
    modifier checkManager() {
        if (!accessControlManager.hasRole(accessControlManager.WATER_MANAGER_ROLE(), msg.sender))
            revert NotAuthorized();
        _;
    }

    // Modifier: allow if caller has either WATER_MANAGER_ROLE or VERIFIER_ROLE.
    modifier checkManagerorVerifier() {
        if (
            !(
                accessControlManager.hasRole(accessControlManager.WATER_MANAGER_ROLE(), msg.sender) ||
                accessControlManager.hasRole(accessControlManager.VERIFIER_ROLE(), msg.sender)
            )
        ) revert NotAuthorized();
        _;
    }
    
    // Function to create a District Factory instance.
    // Only accessible by accounts with WATER_MANAGER_ROLE.
    function createStationContract(
        bytes32 _district_name,
        bytes32 _owner_name,
        address _parent_address,
        bytes32 _parent_name,
        bytes32 _data,
        bytes calldata _signature
    ) external checkManager {
         // Register the new contract via the AccessControlManager.
        accessControlManager.createNewContract(
            _district_name,
            _owner_name,
            address(new StationContract(address(accessControlManager))),
            AccessControlManager.ContractType.stationcontract, 
            _parent_address,
            _parent_name,
            _data,
            _signature
        );
    }

    // Sets the IPFS CID for a given date.
    // Only the WATER_MANAGER_ROLE can call this.
    function setIPFSCID(uint32 _date, bytes32 _cid) external checkManager {
        ipfsCIDs[_date] = _cid;
    }

    // Retrieves the IPFS CID for a given date.
    // Accessible by both VERIFIER_ROLE and WATER_MANAGER_ROLE.
    function getIPFSCID(uint32 _date) external view checkManagerorVerifier returns (bytes32) {
        return ipfsCIDs[_date];
    }
}
