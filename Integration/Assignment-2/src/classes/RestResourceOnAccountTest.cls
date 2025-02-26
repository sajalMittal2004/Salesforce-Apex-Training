@isTest
public with sharing class RestResourceOnAccountTest {

    @TestSetup
    static void makeData(){
        Account acc = new Account(Name = 'Test Account-1', Phone = '123456789');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact-1', AccountId = acc.Id, Email = 'Test1@gmail.com');
        insert con;
    }

    /**
     * Test method for doGet
     * Ensures account retrieval works correctly with valid and invalid account IDs.
     */
    @isTest
    static void testDoGet_Success() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name LIKE 'Test Account-1'];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = 'https://fexleservicespvtltd-c-dev-ed.develop.my.salesforce.com/services/apexrest/AccountApi/'+acc.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            RestResourceOnAccount.doGet();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode, 'Expected status code is 200');
        String responseBody = res.responseBody.toString();
        Assert.isTrue(responseBody.contains(acc.Id), 'Response should contain the Account ID');

    }

    @isTest
    static void testDoGet_Failure() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = 'https://fexleservicespvtltd-c-dev-ed.develop.my.salesforce.com/services/apexrest/AccountApi/InvalidID';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            RestResourceOnAccount.doGet();
        Test.stopTest();

        Assert.areEqual(500, res.statusCode, 'Expected status code is 500');
        String responseBody = res.responseBody.toString();
        Assert.isTrue(responseBody.contains('List has no rows for assignment to SObject'), 'Response should contain the error message');

    }

    @isTest
    static void testDoPost_Success() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'Post';
        req.requestBody = Blob.valueOf('{"accountName":"New Account","firstName":"John","lastName":"Doe","email":"John.Doe@example.com"}');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            String responseBody = RestResourceOnAccount.doPost();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.areEqual('Success', responseMap.get('status'), 'Expected Success status');
        Assert.isNotNull(responseMap.get('data'), 'Response should contain data');
        Assert.areEqual(201, res.statusCode, 'Expected status code 400');
    }

    @isTest
    static void testDoPost_MissingFields() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'Post';
        req.requestBody = Blob.valueOf('{"accountName":"","firstName":"John","lastName":"Doe","email":""}');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            String responseBody = RestResourceOnAccount.doPost();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.isNull(responseMap.get('data'), 'Data should be null');
        Assert.areEqual('Error', responseMap.get('status'), 'Expected error status');
        Assert.isTrue(responseMap.get('message').toString().contains('All fields are required'), 'Expected missing fields error');
        Assert.areEqual(400, res.statusCode, 'Expected status code 400');
    }

    @isTest
    static void testDoPost_ExistingAccount_DuplicateContact() {
        Account existingAccount = [SELECT Id, Name FROM Account LIMIT 1];
        Contact existingContact = [SELECT FirstName, LastName, Email FROM Contact WHERE AccountId = :existingAccount.Id LIMIT 1];
        String body = '{"accountName":"'+existingAccount.Name+
                        '","firstName":"'+existingContact.FirstName+
                        '","lastName":"'+existingContact.LastName+
                        '","email":"'+existingContact.Email+
                    '"}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'Post';
        req.requestBody = Blob.valueOf(body);
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            String responseBody = RestResourceOnAccount.doPost();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.isNotNull(responseMap.get('data'), 'Response should contain data');
        Assert.areEqual('Error', responseMap.get('status'), 'Expected error status');
        Assert.isTrue(responseMap.get('message').toString().contains('Duplicate Contact found for this Account with the same email.'), 
                        'Account and Contact should be created');
        Assert.areEqual(409, res.statusCode, 'Expected status code 409');
    }

    @isTest
    static void testDoPost_ExistingAccount_NewContact() {
        Account existingAccount = [SELECT Id, Name FROM Account LIMIT 1];
        String body = '{"accountName":"'+existingAccount.Name+
                        '","firstName":"'+'New'+
                        '","lastName":"'+'Contact-1'+
                        '","email":"'+'NewContact@example.com'+
                    '"}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'Post';
        req.requestBody = Blob.valueOf(body);
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            String responseBody = RestResourceOnAccount.doPost();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.isNotNull(responseMap.get('data'), 'Response should contain data');
        Assert.areEqual('Success', responseMap.get('status'), 'Expected Success status');
        Assert.isTrue(responseMap.get('message').toString().contains('Account and Contact created Successfully.'), 
                        'Expected missing fields error');
        Assert.areEqual(201, res.statusCode, 'Expected status code 201');
    }

    @isTest
    static void testDoPost_InsertionFailure() {
        Account existingAccount = [SELECT Id, Name FROM Account LIMIT 1];
        String body = '{"accountName":"'+existingAccount.Name+
                        '","firstName":"'+'New'+
                        '","lastName":"'+'Contact-1'+
                        '","email":"'+'NewContact'+
                    '"}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'Post';
        req.requestBody = Blob.valueOf(body);
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            String responseBody = RestResourceOnAccount.doPost();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Assert.isNull(responseMap.get('data'), 'Data should be null');
        Assert.areEqual('Error', responseMap.get('status'), 'Expected error status');
        Assert.isTrue(responseMap.get('message').toString().contains('INVALID_EMAIL_ADDRESS'), 
                                                                        'Expected missing fields error');
        Assert.areEqual(500, res.statusCode, 'Expected status code 500');
    }
}