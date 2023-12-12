// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract user{
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

    uint256 public id_user;
    user_state public actual_user_state;
    Recipient[] public recipients_list;
    Oracle[] public oracles_list;
    bytes32 private contractHash;
    bool isContractClosed; // questa variabile viene settata a true quando viene richiesta la chiusura del contratto

    constructor(uint256 id, bytes32 hash){
        id_user = id;
        actual_user_state = user_state.alive;
        contractHash = hash;
        isContractClosed = false;
    }

    function addRecipient(uint256 recipientId) public { // non deve essere public
        Recipient memory new_recipient;
        new_recipient.id_recipient = recipientId;
        recipients_list.push(new_recipient);
    }

    function addOracle(uint256 oracleId) public { // non deve essere public
        Oracle memory new_oracle;
        new_oracle.id_oracle = oracleId;
        oracles_list.push(new_oracle);
    }

    function setUserStateToDeceased() public{
        actual_user_state = user_state.deceased;
    }

    function setRecipientTimeStamp(uint256 recipientId, string memory timestamp) public{
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                recipients_list[i].timestamp = timestamp;
            }
        }
    }

    function setRecipientResponse(uint256 recipientId, bool response, bool isTimeExpired) public {
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                recipients_list[i].response = response;
                recipients_list[i].isTimeExpired = isTimeExpired;
            }
        }
    }

    function closeUserContract() public{
        isContractClosed = true; // non permette di chiamare tutte le altre funzioni
    }

    // Debugging functions

    function getUserId() public view returns (uint256){
        return id_user;
    }

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

contract lincloud_contract{

    enum user_state {deceased, alive}
    user[] public users_list;

    function createNewUserContract(uint256 userId, bytes32 contractHash) public {  // Crea un nuovo utente e aggiungilo alla lista degli utenti
        require(!isUserExist(userId), "Utente esistente"); // controllo che l'utente non sia sulla lista
        user newUser = new user(userId, contractHash);
        users_list.push(newUser);
    }

    function addNewRecipient(uint256 userId, uint256 recipientId) public {
        require(isUserExist(userId), "Utente non trovato");
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                users_list[i].addRecipient(recipientId);
            }
        }
    }

    function addNewOracle(uint256 userId, uint256 oracleId) public {
        require(isUserExist(userId), "Utente non trovato");
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                users_list[i].addOracle(oracleId);
            }
        }
    }

    function userDeathNotify(uint256 userId) public{
        require(isUserExist(userId), "Utente non trovato");
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                users_list[i].setUserStateToDeceased();
            }
        }
    }

    function updateTimestamp(uint256 userId, uint256 recipientId, string memory timestamp) public{
        require(isUserExist(userId), "Utente non trovato");
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                users_list[i].setRecipientTimeStamp(recipientId, timestamp);
            }
        }
    }

    function recipientResponse(uint256 userId, uint256 recipientId, bool response, bool isTimeExpired) public {
        require(isUserExist(userId), "Utente non trovato");
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                users_list[i].setRecipientResponse(recipientId, response, isTimeExpired);
            }
        }
    }

    function closeUserContractNotify(uint256 userId) public {
        require(isUserExist(userId), "Utente non trovato");
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                users_list[i].closeUserContract();
            }
        }
    }

    // Debugging functions

    function isUserExist(uint256 userId) internal view returns (bool) {
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                return true;
            }
        }
        return false;
    }

    function getAllUsers() public view returns (uint256[] memory) {
        uint256[] memory userIDs = new uint256[](users_list.length);
        for (uint256 i = 0; i < users_list.length; i++) {
            userIDs[i] = users_list[i].getUserId();
        }
        return userIDs;
    }

    function getAllRecipients(uint256 userId) public view returns (uint256[] memory){
        require(isUserExist(userId), "Utente non trovato");
        uint256[] memory recipientsIds = new uint256[](users_list.length);
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                recipientsIds = users_list[i].getAllRecipients();
            }
        }
        return recipientsIds;
    }
    
    function getAllOracles(uint256 userId) public view returns (uint256[] memory){
        require(isUserExist(userId), "Utente non trovato");
        uint256[] memory oraclesIds = new uint256[](users_list.length);
        for (uint256 i = 0; i < users_list.length; i++) {
            if (users_list[i].id_user() == userId) {
                oraclesIds = users_list[i].getAllOracles();
            }
        }
        return oraclesIds;
    }

}
