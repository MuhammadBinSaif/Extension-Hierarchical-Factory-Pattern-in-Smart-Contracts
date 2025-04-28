// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./SuperFactory.sol";

// Custom errors to reduce gas when reverting.
error NotAuthorized();
error InvalidAddress();
error NewAdminSameAsCurrent();

contract AccessControlManager {
    // ECDSA library to recover user address from signature
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Role constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant WATER_MANAGER_ROLE = keccak256("WATER_MANAGER");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER");

    address private AdminOwner;

    // struct for contract data
    struct ContractData {
        address contractAddress; // 20 bytes
        ContractType contractType; // enum (1 byte ideally)
        address ownerAddress; // 20 bytes
        address parentContractAddress; // 20 bytes
        bytes32 ownerName; // 32 bytes
        bytes32 name; // 32 bytes
        bytes32 parentName; // 32 bytes
    }

    // enum for contract types
    enum ContractType {
        ACM,
        superfactory,
        cityfactory,
        distictfactory,
        stationcontract
    }
    // mapping to store roles against users and contracts
    mapping(bytes32 => mapping(address => ContractData[]))
        public  accesscontrol;

    // constructor to initialize and deploy super factory with deployer address as ADMIN
    constructor() {
        createNewContract(
            ADMIN_ROLE,
            msg.sender,
            address(this),
            msg.sender,
            address(this),
            "ACM",
            "ACM",
            "No",
            ContractType.ACM
        );
        createNewContract(
            ADMIN_ROLE,
            msg.sender,
            address(new SuperFactory(address(this))),
            msg.sender,
            address(this),
            "Super_Factory",
            "Super_Factory",
            "No",
            ContractType.superfactory
        );
        AdminOwner = msg.sender;
    }

    // modifier to check the admin role
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert NotAuthorized();
        _;
    }

    // modifier to check the client role
    modifier onlyManager() {
        if (!hasRole(WATER_MANAGER_ROLE, msg.sender)) revert NotAuthorized();
        _;
    }

    // internal function to recover user address from signature
    function _authnz(bytes32 data, bytes calldata signature)
        internal
        pure
        returns (address)
    {
        return data.toEthSignedMessageHash().recover(signature);
    }

    // Check if a user holds a particular role (simply by having at least one ContractData entry).
    function hasRole(bytes32 _role, address _user) public view returns (bool) {
        return accesscontrol[_role][_user].length > 0;
    }

    // external function to add new contracts in mapping on behalf of client user
    function addContractOnBehalfOfManager(
        address _contract_address,
        address _owner_address,
        address _parent_address,
        bytes32 _owner_name,
        bytes32 _name,
        bytes32 _parent_name,
        bytes32 _data,
        bytes calldata _signature,
        ContractType _contract_type
    ) external {
        address signer = _authnz(_data, _signature);
        if (!hasRole(ADMIN_ROLE, signer)) revert NotAuthorized();
        createNewContract(
            WATER_MANAGER_ROLE,
            _owner_address,
            _contract_address,
            _owner_address,
            _parent_address,
            _owner_name,
            _name,
            _parent_name,
            _contract_type
        );
        createNewContract(
            ADMIN_ROLE,
            signer,
            _contract_address,
            _owner_address,
            _parent_address,
            _owner_name,
            _name,
            _parent_name,
            _contract_type
        );
    }

    // external function called by client to add new contracts and data in struct mapping
    function createNewContract(
        bytes32 _name,
        bytes32 _owner_name,
        address _contract_address,
        ContractType _contract_type,
        address _parent_contract_address,
        bytes32 _parent_name,
        bytes32 _data,
        bytes calldata _signature
    ) external {
        address signer = _authnz(_data, _signature);
        if (!hasRole(WATER_MANAGER_ROLE, signer)) revert NotAuthorized();
        ContractData memory newcontract = ContractData({
            contractAddress: _contract_address,
            ownerAddress: signer,
            parentContractAddress: _parent_contract_address,
            ownerName: _owner_name,
            name: _name,
            parentName: _parent_name,
            contractType: _contract_type
        });
        accesscontrol[WATER_MANAGER_ROLE][signer].push(newcontract);
        accesscontrol[ADMIN_ROLE][AdminOwner].push(newcontract);
    }

        function addVerifier(address _verifierAddress) external onlyAdmin {
        // Revert if the address is invalid (zero address)
        if (_verifierAddress == address(0)) revert InvalidAddress();

        // Add a placeholder ContractData entry using the private helper function
        // to grant the VERIFIER_ROLE.
        createNewContract(
            VERIFIER_ROLE,              // The role to grant
            _verifierAddress,           // The user receiving the role
            address(0),                 // Placeholder contract address (not specific)
            _verifierAddress,           // Owner is the verifier themselves here
            address(0),                 // Placeholder parent address
            bytes32("Verifier"),        // Placeholder owner name (as bytes32)
            bytes32("RoleGrant"),       // Placeholder name indicating purpose (as bytes32)
            bytes32("N/A"),             // Placeholder parent name (as bytes32)
            ContractType.ACM            // Using ACM as a generic type, adjust if needed
        );
    }

    // external function to transfer ownership of ADMIN role to new address
    function transferOwnership(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAddress();
        if (newAdmin == AdminOwner) revert NewAdminSameAsCurrent();

        // Transfer all ContractData from the old admin to the new admin
        ContractData[] storage oldAdminContracts = accesscontrol[ADMIN_ROLE][AdminOwner];
        ContractData[] storage newAdminContracts = accesscontrol[ADMIN_ROLE][newAdmin];

        for (uint i = 0; i < oldAdminContracts.length; ) {
            newAdminContracts.push(oldAdminContracts[i]);
            unchecked { ++i; }
        }
        delete accesscontrol[ADMIN_ROLE][AdminOwner];
        AdminOwner = newAdmin;
    }

    //Function to revoke role of user
    function revokeRole(bytes32 role, address user) external onlyAdmin {
        if (user == address(0)) revert InvalidAddress();
        delete accesscontrol[role][user];
    }

    // seprate private function to add contract data in struct
    // purpose of this function is to remove code repetition
    function createNewContract(
        bytes32 _role,
        address _user,
        address _contract_address,
        address _owner_address,
        address _parent_address,
        bytes32 _owner_name,
        bytes32 _name,
        bytes32 _parent_name,
        ContractType _contract_type
    ) private {
        ContractData memory newcontract = ContractData({
            contractAddress: _contract_address,
            ownerAddress: _owner_address,
            parentContractAddress: _parent_address,
            ownerName: _owner_name,
            name: _name,
            parentName: _parent_name,
            contractType: _contract_type
        });
        accesscontrol[_role][_user].push(newcontract);
    }
}
