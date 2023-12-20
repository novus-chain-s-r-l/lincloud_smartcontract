// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract lincloud_contract 
{

    address public owner; // creatore e proprietario del contratto
    user_contract[] user_contracts_list; // lista dei contratti creati
    mapping(uint256 => address) public contract_user_map; // mappa userId -> indirizzo del contratto utente
    enum user_state {deceased, alive}   
    
    constructor() {
        owner = msg.sender;
    }

    function createNewUserContract(uint256 userId, string memory contractHash) public {  // Crea un nuovo utente e aggiungilo alla lista degli utenti
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist"); // controllo che l'utente non sia sulla lista
        user_contract newUserContract = new user_contract(userId, contractHash);
        user_contracts_list.push(newUserContract);
        contract_user_map[userId] = address(newUserContract);
    }

    function addNewRecipient(uint256 userId, uint256 recipientId) public { // aggiungi un nuovo destinatario per l'utente specificato
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].addRecipient(recipientId);
            }
        }
    }

    function addNewOracle(uint256 userId, uint256 oracleId) public {
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].addOracle(oracleId);
            }
        }
    }

    function userDeathNotify(uint256 userId) public {
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].setUserStateToDeceased();
            }
        }
    }

    function updateTimestamp(uint256 userId, uint256 recipientId, string memory timestamp) public {
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].setRecipientTimeStamp(recipientId, timestamp);
            }
        }
    }

    function recipientResponse(uint256 userId, uint256 recipientId, bool isAccepted, bool isTimeExpired) public {
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].setRecipientResponse(recipientId, isAccepted, isTimeExpired);
            }
        }
    }

    function closeUserContractNotify(uint256 userId) public {
        require(msg.sender == owner);
        require(!isUserExist(userId), "User already exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].closeUserContract();
            }
        }
    }

    function isUserExist(uint256 userId) internal view returns (bool) {
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                return true;
            }
        }
        return false;
    }

    // Getters & Setters

    // ritorna gli id di tutti gli utenti creati
    function getAllUsersId() public view returns (uint256[] memory) {
        uint256[] memory userIds = new uint256[](user_contracts_list.length);
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            userIds[i] = user_contracts_list[i].userId();
        }
        return userIds;
    }

    // function getAllRecipients(uint256 userId) public view returns (uint256[] memory){
    //     require(isUserExist(userId), "Utente non trovato");
    //     uint256[] memory recipientsIds = new uint256[](users_list.length);
    //     for (uint256 i = 0; i < users_list.length; i++) {
    //         if (users_list[i].id_user() == userId) {
    //             recipientsIds = users_list[i].getAllRecipients();
    //         }
    //     }
    //     return recipientsIds;
    // }
    
    // function getAllOracles(uint256 userId) public view returns (uint256[] memory){
    //     require(isUserExist(userId), "Utente non trovato");
    //     uint256[] memory oraclesIds = new uint256[](users_list.length);
    //     for (uint256 i = 0; i < users_list.length; i++) {
    //         if (users_list[i].id_user() == userId) {
    //             oraclesIds = users_list[i].getAllOracles();
    //         }
    //     }
    //     return oraclesIds;
    // }

}

contract user_contract
{
    address public owner;
    uint256 public userId;
    string public contractHash;
    bool public isContractClosed; // questa variabile viene settata a true quando viene richiesta la chiusura del contratto
    user_state public actual_user_state;
    Recipient[] public recipients_list;
    Oracle[] public oracles_list;
    enum user_state {deceased, alive}
    
    struct Recipient {
        uint256 id_recipient;
        string timestamp;
        bool response;
        bool isTimeExpired;
    }

    struct Oracle {
        uint256 id_oracle;
    }

    constructor(uint256 _id, string memory _hash) {
        userId = _id;
        actual_user_state = user_state.alive;
        contractHash = _hash;
        isContractClosed = false;
        for(uint256 i = 0; i < recipients_list.length; i++){
            recipients_list[i].timestamp = "";
        }
    }

    function addRecipient(uint256 recipientId) external { 
        require(isContractClosed == false, "Smart Contract is closed");
        Recipient memory new_recipient;
        new_recipient.id_recipient = recipientId;
        recipients_list.push(new_recipient);
    }

    function addOracle(uint256 oracleId) external { 
        require(isContractClosed == false, "Smart Contract is closed");
        Oracle memory new_oracle;
        new_oracle.id_oracle = oracleId;
        oracles_list.push(new_oracle);
    }

    function setUserStateToDeceased() external {
        require(actual_user_state == user_state.alive, "User deceased is already set");
        require(isContractClosed == false, "Smart Contract is closed");
        actual_user_state = user_state.deceased;
    }

    function setRecipientTimeStamp(uint256 recipientId, string memory timestamp) external {
        require(isContractClosed == false, "Smart Contract is closed");
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                recipients_list[i].timestamp = timestamp;
            }
        }
    }

    function setRecipientResponse(uint256 recipientId, bool isAccepted, bool isTimeExpired) external {
        require(isContractClosed == false, "Smart Contract is closed");
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                recipients_list[i].response = isAccepted;
                recipients_list[i].isTimeExpired = isTimeExpired;
            }
        }
    }

    function closeUserContract() external {
        require(isContractClosed == false, "Smart Contract is closed");
        isContractClosed = true; // le funzioni dello smart contract non saranno più disponibili
    }

    // Getters & Setters

    function getAllRecipients() public view returns (uint256[] memory){
        uint256[] memory recipientIDs = new uint256[](recipients_list.length);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            recipientIDs[i] = recipients_list[i].id_recipient;
        }
        return recipientIDs;
    }

    function getAllOracles() public view returns (uint256[] memory){
        uint256[] memory oraclesIds = new uint256[](oracles_list.length);
        for (uint256 i = 0; i < oracles_list.length; i++) {
            oraclesIds[i] = oracles_list[i].id_oracle;
        }
        return oraclesIds;
    }
}
