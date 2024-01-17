// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
contract lincloud_contract 
{
    address public owner; // creatore e proprietario del contratto
    user_contract[] user_contracts_list; // lista dei contratti creati
    mapping(uint256 => address) public contract_user_map; // mappa userId -> indirizzo del contratto utente
    enum user_state {deceased, alive}  

    event Recipient(uint256[] _value);
    event UserId(uint256[] _value);
    event Oracle(uint256[] _value);
    event UserState(string _value);
    event TimeStamp(string _value);
    event Response(string _value);
    event ContractState(string _value);
    
    constructor() {
        owner = msg.sender;
    }

    function createNewUserContract(uint256 userId, string memory contractHash) public {  // Crea un nuovo utente e aggiungilo alla lista degli utenti
        require(msg.sender == owner);
        require(isUserExist(userId) == false, "User already exist"); // controllo che l'utente non sia sulla lista
        user_contract newUserContract = new user_contract(userId, contractHash); // creo un nuovo contratto utente
        user_contracts_list.push(newUserContract); // il contratto creato viene memorizzato in una lista
        contract_user_map[userId] = address(newUserContract); // aggiungo alla mappa id utente e contratto appena creato
    }

    function addNewRecipient(uint256 userId, uint256 recipientId) public { // Aggiunge un nuovo destinatario per l'utente specificato
        require(msg.sender == owner);
        require(isUserExist(userId) == true, "User doesn't exist"); 
        require(isRecipientExist(userId, recipientId) == false, "Recipient Already exist"); // richiede che il destiantario non sia presente
        for (uint256 i = 0; i < user_contracts_list.length; i++) { // ricerca dell'utente richiesto 
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].addRecipient(recipientId); // Richiama addRecipient() dello user contract
            }
        }
    }
 
    function addNewOracle(uint256 userId, uint256 oracleId) public { // Aggiunge un nuovo Oracolo
        require(msg.sender == owner);
        require(isUserExist(userId) == true, "User doesn't exist");
        require(isOracleExist(userId, oracleId) == false, "Oracle Already exist"); // richiede che l'oracolo non sia presente
        for (uint256 i = 0; i < user_contracts_list.length; i++) { // ricerca dell'utente richiesto 
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].addOracle(oracleId); // Richiama addOracle() dello user contract
            }
        }
    }

    function userDeathNotify(uint256 userId) public { // Cambia lo stato vitale dell'utente
        require(msg.sender == owner);
        require(isUserExist(userId) == true, "User doesn't exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].setUserStateToDeceased();
            }
        }
    }

    function updateTimestamp(uint256 userId, uint256 recipientId, string memory time, string memory date) public { // Aggiorna il timestamp
        require(msg.sender == owner);
        require(isUserExist(userId) == true, "User doesn't exist");
        require(isRecipientExist(userId, recipientId) == true, "Recipient doesn't exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].setRecipientTimeStamp(recipientId, time, date);
            }
        }
    }

    function recipientResponse(uint256 userId, uint256 recipientId, bool isAccepted, bool isTimeExpired) public { // Inserisce la risposta del destinatario
        require(msg.sender == owner);
        require(isUserExist(userId) == true, "User doesn't exist");
        require(isRecipientExist(userId, recipientId) == true, "Recipient doesn't exist");
        require(isResponseOk(isAccepted, isTimeExpired) == true, "If eredity is 'Accepted' time can't be 'Expired'");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].setRecipientResponse(recipientId, isAccepted, isTimeExpired);
            }
        }
    }

    function closeUserContract(uint256 userId) public {
        require(msg.sender == owner);
        require(isUserExist(userId) == true, "User doesn't exist");
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                user_contracts_list[i].closeUserContract();
            }
        }
    }

    // Debugging functions

    function isResponseOk(bool isAccepted, bool isTimeExpired) internal pure returns (bool){
        if(isAccepted == true && isTimeExpired == true){
            return false;
        }
        return true;
    }

    function isUserExist(uint256 userId) internal view returns (bool) {
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                return true;
            }
        }
        return false;
    }

    function isRecipientExist(uint256 userId, uint256 recipientsId) internal view returns (bool) {
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                uint256[] memory recIds = user_contracts_list[i].getAllRecipients();
                for(uint256 j = 0; j < recIds.length; j++){
                    if(recIds[j] == recipientsId){
                        return true; // già esistente
                    }
                }
            }
        }
        return false; // destiantario non presente
    }

    function isOracleExist(uint256 userId, uint256 oraclesIds) internal view returns (bool) {
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                uint256[] memory oracIds = user_contracts_list[i].getAllOracles();
                for(uint256 j = 0; j < oracIds.length; j++){
                    if(oracIds[j] == oraclesIds){
                        return true; // già esistente
                    }
                }
            }
        }
        return false; // oracolo non presente
    }

    // Getters

    function getAllUsersId() public{
        uint256[] memory userIds = new uint256[](user_contracts_list.length);
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            userIds[i] = user_contracts_list[i].userId();
        }
        emit UserId(userIds);
    }

    function getAllRecipients(uint256 userId) public{
        require(isUserExist(userId) == true, "User doesn't exist"); 
        uint256[] memory recipientsIds = new uint256[](user_contracts_list.length);
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                recipientsIds = user_contracts_list[i].getAllRecipients();
            }
        }
        emit Recipient(recipientsIds);
    }
    
    function getAllOracles(uint256 userId) public{
        require(isUserExist(userId) == true, "User doesn't exist"); 
        uint256[] memory oraclesIds = new uint256[](user_contracts_list.length);
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                oraclesIds = user_contracts_list[i].getAllOracles();
            }
        }
        emit Oracle(oraclesIds);
    }

    function getUserState(uint256 userId) public{
        require(isUserExist(userId) == true, "User doesn't exist"); 
        string memory userState = ""; 
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                userState = user_contracts_list[i].getUserState();
            }
        }
        emit UserState(userState);
    }
    
    function getRecipientTimeStamp(uint256 userId, uint256 recipientId) public{
        require(isUserExist(userId) == true, "User doesn't exist"); 
        require(isRecipientExist(userId, recipientId) == true, "Recipient doesn't exist");
        string memory timeStamp = "No timestamp";
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                timeStamp = user_contracts_list[i].getRecipientTimeStamp(recipientId);
            }
        }
        emit TimeStamp(timeStamp);
    }

    function getRecipientResponse(uint256 userId, uint256 recipientId) public{
        require(isUserExist(userId) == true, "User doesn't exist"); 
        require(isRecipientExist(userId, recipientId) == true, "Recipient doesn't exist");
        string memory response = "No response";
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                response = user_contracts_list[i].getRecipientResponse(recipientId);
            }
        }
        emit Response(response);
    }

    function getUserContractState(uint256 userId) public{
        require(isUserExist(userId) == true, "User doesn't exist");
        string memory state = "";
        for (uint256 i = 0; i < user_contracts_list.length; i++) {
            if (user_contracts_list[i].userId() == userId) {
                state = user_contracts_list[i].getContractState();
            }
        }
        emit ContractState(state);
    }
}

contract user_contract
{
    address public owner;
    uint256 public userId;
    string public contractHash;
    bool public isContractClosed; // true quando viene richiesta la chiusura del contratto
    bool public isTimeStampSet; // se true, il timestamp non può essere più cambiato. max 1 volta
    bool public isRecipientResponseSet; // se true, la risposta non può essere aggiornata. max 1 volta
    user_state public actual_user_state;
    Recipient[] public recipients_list;
    Oracle[] public oracles_list;
    enum user_state {deceased, alive}
    enum recipient_response_state {accepted, rejected, nodata}
    
    struct Recipient {
        uint256 id_recipient;
        string time;
        string date;
        recipient_response_state responseState;
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
        isTimeStampSet = false;
        isRecipientResponseSet = false;
        owner = msg.sender;
    }

    function addRecipient(uint256 recipientId) external { 
        require(msg.sender == owner);
        require(isContractClosed == false, "Smart Contract is closed");
        Recipient memory new_recipient;
        new_recipient.id_recipient = recipientId;
        new_recipient.responseState = recipient_response_state.nodata;
        new_recipient.time = "nodata";
        new_recipient.date = "nodata";
        new_recipient.isTimeExpired = false;
        recipients_list.push(new_recipient);
    }

    function addOracle(uint256 oracleId) external { 
        require(msg.sender == owner);
        require(isContractClosed == false, "Smart Contract is closed");
        Oracle memory new_oracle;
        new_oracle.id_oracle = oracleId;
        oracles_list.push(new_oracle);
    }

    function setUserStateToDeceased() external {
        require(msg.sender == owner);
        require(actual_user_state == user_state.alive, "User deceased is already set");
        require(isContractClosed == false, "Smart Contract is closed");
        actual_user_state = user_state.deceased;
    }

    function setRecipientTimeStamp(uint256 recipientId, string memory time, string memory date) external {
        require(msg.sender == owner);
        require(isContractClosed == false, "Smart Contract is closed");
        require(actual_user_state == user_state.deceased, "User is still alive");
        require(isTimeStampSet == false, "Time Stamp already set");
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                recipients_list[i].time = time;
                recipients_list[i].date = date;
                isTimeStampSet = true;
            }            
        }
    }

    function setRecipientResponse(uint256 recipientId, bool isAccepted, bool isTimeExpired) external {
        require(msg.sender == owner);
        require(isContractClosed == false, "Smart Contract is closed");
        require(actual_user_state == user_state.deceased, "User is still alive");
        require(isRecipientResponseSet == false, "Recipient Response already set");
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                if(isAccepted == true){
                    recipients_list[i].responseState = recipient_response_state.accepted;
                }else{
                    recipients_list[i].responseState = recipient_response_state.rejected;
                }
                recipients_list[i].isTimeExpired = isTimeExpired;
                isRecipientResponseSet = true;
            }
        }
    }

    function closeUserContract() external {
        require(msg.sender == owner);
        require(isContractClosed == false, "Smart Contract is closed");
        require(actual_user_state == user_state.deceased, "User is still alive");
        isContractClosed = true; // le funzioni dello smart contract non saranno più disponibili
    }

    // Getters

    function getAllRecipients() external view returns (uint256[] memory){
        require(msg.sender == owner);
        uint256[] memory recipientIDs = new uint256[](recipients_list.length);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            recipientIDs[i] = recipients_list[i].id_recipient;
        }
        return recipientIDs;
    }

    function getAllOracles() external view returns (uint256[] memory){
        require(msg.sender == owner);
        uint256[] memory oraclesIds = new uint256[](oracles_list.length);
        for (uint256 i = 0; i < oracles_list.length; i++) {
            oraclesIds[i] = oracles_list[i].id_oracle;
        }
        return oraclesIds;
    }

    function getUserState() external view returns (string memory){
        require(msg.sender == owner);
        if(actual_user_state == user_state.deceased){
            return "Deceased";
        }else{
            return "Alive";
        }
    }

    function getRecipientTimeStamp(uint256 recipientId) external view returns(string memory){
        require(msg.sender == owner);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if(recipients_list[i].id_recipient == recipientId){
                return string.concat(string.concat(recipients_list[i].date, " "), recipients_list[i].time);
            }
        }
        return "nodata";
    }

    function getRecipientResponse(uint256 recipientId) external view returns(string memory){
        require(msg.sender == owner);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if(recipients_list[i].id_recipient == recipientId){
                if(recipients_list[i].responseState == recipient_response_state.accepted){
                    return "Accepted";
                }else if (recipients_list[i].responseState == recipient_response_state.rejected
                && recipients_list[i].isTimeExpired == false){
                    return "Rejected";
                }else if (recipients_list[i].responseState == recipient_response_state.rejected
                && recipients_list[i].isTimeExpired == true){
                    return "Rejected, time expired: no response from recipient";
                }
            }
        }
        return "nodata";
    }

    function getContractState() external view returns(string memory){
        require(msg.sender == owner);
        if(isContractClosed == true){
            return "Contract Closed";
        }else{
            return "Contract Open";
        }
    }
}
