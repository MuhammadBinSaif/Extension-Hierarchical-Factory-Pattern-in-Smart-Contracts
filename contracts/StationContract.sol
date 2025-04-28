// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlManager.sol";

contract StationContract {
    // Use an immutable variable for the access control manager.
    AccessControlManager private immutable accessControlManager;

    // Mapping from a date (uint32, e.g., YYYYMMDD) to an IPFS CID (bytes32 digest).
    mapping(uint32 => bytes32) private ipfsCIDs;

    // Constructor sets the AccessControlManager address once.
    constructor(address _accessControlAddress) {
        accessControlManager = AccessControlManager(_accessControlAddress);
    }

    // Modifier to restrict access to callers with VERIFIER or WATER_MANAGER roles.
    modifier onlyAuthorized() {
        if (
            !(
                accessControlManager.hasRole(accessControlManager.VERIFIER_ROLE(), msg.sender) ||
                accessControlManager.hasRole(accessControlManager.WATER_MANAGER_ROLE(), msg.sender)
            )
        ) revert NotAuthorized();
        _;
    }

    // Stores an IPFS CID for a given date.
    function setIPFSCID(uint32 _date, bytes32 _cid) external onlyAuthorized {
        ipfsCIDs[_date] = _cid;
    }

    // Retrieves the IPFS CID stored for a given date.
    function getIPFSCID(uint32 _date) external view onlyAuthorized returns (bytes32) {
        return ipfsCIDs[_date];
    }
}
