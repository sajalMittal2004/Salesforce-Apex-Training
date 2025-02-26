/**
 * Purpose        : This class serves as a RESTful API on Account.
 * 
 * Created by     : Sajal Mittal
 * 
 * Created Date   : 24-02-2025
 * 
 * Revision Logs  : V_1.0 - Created
 */
@RestResource(urlMapping='/AccountApi/*')
global with sharing class RestResourceOnAccount {

    /**
     * Method Name  :   doGet
     * 
     * Created by   :   Sajal Mittal
     * 
     * Purpose      :   Method to handle HTTP GET requests
     * 
     * return       :   Returns a JSON object containing Account details or an error message in case of failure
     *    
    **/
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.Request;
        RestResponse res = RestContext.Response;

        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        try {
            Account acc = [SELECT Id, Name, Phone FROM Account WHERE Id =: accountId];
            res.responseBody = Blob.valueOf(JSON.serialize(acc));
            res.statusCode = 200;
        } catch(Exception e) {
            res.responseBody = Blob.valueOf(e.getMessage());
            res.statusCode = 500;
        }        
    }

    /**
     * Method Name  :   doPost
     * 
     * Created by   :   Sajal Mittal
     * 
     * Purpose      :   Method to handle HTTP POST requests
     * 
     * return       :   Returns a JSON object with created AccountId and ContactId or an error message in case of failure
     * 
    **/
    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.Request;
        RestResponse res = RestContext.Response;
        RestResourceOnAccount_Response response = new RestResourceOnAccount_Response();

        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String accountName = (String) requestBody.get('accountName');
        String firstName = (String) requestBody.get('firstName');
        String lastName = (String) requestBody.get('lastName');
        String email = (String) requestBody.get('email');

        if(String.isBlank(accountName) || String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
            response.status = 'Error';
            response.message = 'All fields are required.';
            res.statusCode = 400;
            response.data = null;
            return JSON.serialize(response);
        }

        List<Account> existingAccounts = [SELECT Id FROM Account WHERE Name =: accountName LIMIT 1];
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        Account acc;


        if(!existingAccounts.isEmpty()) {
            acc = existingAccounts[0];
            List<Contact> existingContacts = [SELECT Id FROM Contact WHERE AccountId =: acc.Id AND Email =: email LIMIT 1];

            if(!existingContacts.isEmpty()) {
                response.status = 'Error';
                response.message = 'Duplicate Contact found for this Account with the same email.';
                res.statusCode = 409;
                response.data = new Map<String, Object>{'accountId' => acc.Id};
                return JSON.serialize(response);
            } else {
                newContacts.add(new Contact(FirstName = firstName,
                                         LastName = lastName,
                                         Email = email,
                                         AccountId = acc.Id));
            
                
            }
        } else {
            acc = new Account(Name = accountName, Phone='7981320');
            newAccounts.add(acc);

            if(!newAccounts.isEmpty()) {
                insert newAccounts;
            }

            newContacts.add(new Contact(FirstName = firstName,
                                         LastName = lastName,
                                         Email = email,
                                         AccountId = acc.Id));
        }

        if(!newContacts.isEmpty()) {
            try {
                insert newContacts;
            } catch(Exception e) {
                response.status = 'Error';
                response.message = e.getMessage();
                res.statusCode = 500;
                response.data = null;
                return JSON.serialize(response);
            }
        }
        response.status = 'Success';
        response.message = 'Account and Contact created Successfully.';
        res.statusCode = 201;
        response.data = new Map<String, Object>{'accountId' => acc.Id,
                                                'contactId' => newContacts[0].Id};
        return JSON.serialize(response);
    }
}