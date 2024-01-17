// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract user_contract_interaction{



} 

contract user_contract
{
    address public owner;
    uint256 public userId;
    string public contractHash;
    bool public isContractClosed; // true quando viene richiesta la chiusura del contratto
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
        owner = msg.sender;
    }

    function createInstance(uint256 _id, string memory _hash) external{
        // Implementazione della logica per la creazione di una nuova istanza
        // Assicurarsi di gestire l'allocazione di risorse e altri dettagli specifici
        //address newInstance = address(new user_contract(_id, _hash));
        user_contract newInstance = new user_contract(_id, _hash);
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
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                recipients_list[i].time = time;
                recipients_list[i].date = date;
            }            
        }
    }

    function setRecipientResponse(uint256 recipientId, bool isAccepted, bool isTimeExpired) external {
        require(msg.sender == owner);
        require(isContractClosed == false, "Smart Contract is closed");
        require(actual_user_state == user_state.deceased, "User is still alive");
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if (recipients_list[i].id_recipient == recipientId) {
                //recipients_list[i].isAccepted = isAccepted;
                if(isAccepted == true){
                    recipients_list[i].responseState = recipient_response_state.accepted;
                }else{
                    recipients_list[i].responseState = recipient_response_state.rejected;
                }
                recipients_list[i].isTimeExpired = isTimeExpired;
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

    function getAllRecipients() public view returns (uint256[] memory){
        require(msg.sender == owner);
        uint256[] memory recipientIDs = new uint256[](recipients_list.length);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            recipientIDs[i] = recipients_list[i].id_recipient;
        }
        return recipientIDs;
    }

    function getAllOracles() public view returns (uint256[] memory){
        require(msg.sender == owner);
        uint256[] memory oraclesIds = new uint256[](oracles_list.length);
        for (uint256 i = 0; i < oracles_list.length; i++) {
            oraclesIds[i] = oracles_list[i].id_oracle;
        }
        return oraclesIds;
    }

    function getUserState() public view returns (string memory){
        require(msg.sender == owner);
        if(actual_user_state == user_state.deceased){
            return "Deceased";
        }else{
            return "Alive";
        }
    }

    function getRecipientTimeStamp(uint256 recipientId) public view returns(string memory){
        require(msg.sender == owner);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if(recipients_list[i].id_recipient == recipientId){
                return string.concat(string.concat(recipients_list[i].date, " "), recipients_list[i].time);
            }
        }
        return "nodata";
    }

    function getRecipientResponse(uint256 recipientId) public view returns(string memory){
        require(msg.sender == owner);
        for (uint256 i = 0; i < recipients_list.length; i++) {
            if(recipients_list[i].id_recipient == recipientId){
                //response = recipients_list[i].isAccepted;
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

    function getContractState() public view returns(string memory){
        require(msg.sender == owner);
        if(isContractClosed == true){
            return "Contract Closed";
        }else{
            return "Contract Open";
        }
    }
}