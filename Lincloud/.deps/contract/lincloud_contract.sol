// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface user_contract {
    function createInstance() external returns (address);
}

contract lincloud_contract 
{
    address public owner; // creatore e proprietario del contratto
    address public user_contract_address = 0x953cf28235EE3fBf312A1dACf59353b3c60AE93B;
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

    // function createContract2Instance() external {
    //     Contract2 contract2 = Contract2(contract2Address);
    //     address newInstance = contract2.createInstance();
        
    //     // Puoi fare qualcos'altro con la nuova istanza, se necessario
    //     // Ad esempio, emitire un evento o registrare l'istanza in una struttura dati
    // }

    function createNewUserContract(uint256 userId, string memory contractHash) public {  // Crea un nuovo utente e aggiungilo alla lista degli utenti
        require(msg.sender == owner);
        require(isUserExist(userId) == false, "User already exist"); // controllo che l'utente non sia sulla lista
        //user_contract newUserContract = new user_contract(userId, contractHash); // creo un nuovo contratto utente
        //user_contracts_list.push(newUserContract); // il contratto creato viene memorizzato in una lista
        //contract_user_map[userId] = address(newUserContract); // aggiungo alla mappa id utente e contratto appena creato

        user_contract newUserContract = user_contract(user_contract_address);
        address newInstance = newUserContract.createInstance();
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