/**
 * Purpose      :   Test class for AddressVerificationHandler
 * 
 * Created by   :   Sajal Mittal
 * 
 * Created Date :   26-02-2025
 * 
 * Rivision Logs    :   V_1.0 - Created
 */
@isTest
public with sharing class AddressVerificationHandlerTest {

    /**
     * Mock class for simulating HTTP response from SmartyStreet API.
     */
    public with sharing class HttpMockFactory implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('[{"analysis": {"dpv_match_code": "Y"}}]');
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Test method for 'verifyAddress'.
     * Ensures that the mailing address is verified and the field Is_Mailing_Address_Verified__c is updated.
     */
    @isTest
    static void verifyAddressTest() {
        Contact testContact1 = new Contact(LastName = 'Test Contact',
                                            MailingStreet = '16701 SW 72nd Ave',
                                            MailingCity = 'Palmetto Bay',
                                            MailingState = 'FL',
                                            MailingCountry = 'USA'
                                        );
                                        
        Contact testContact2 = new Contact(LastName = 'Test Contact',
            MailingStreet = '16701 SW 72nd Ave',
            MailingPostalCode = '33157',
            MailingCountry = 'USA'
        );
                                    
        insert testContact1;
        insert testContact2;

        Test.setMock(HttpCalloutMock.class, new HttpMockFactory());

        Test.startTest();
            AddressVerificationHandler.verifyAddress(
                testContact1.MailingStreet,
                testContact1.MailingCity,
                testContact1.MailingState,
                testContact1.MailingPostalCode,
                testContact1.Id
            );
            AddressVerificationHandler.verifyAddress(
                testContact2.MailingStreet,
                testContact2.MailingCity,
                testContact2.MailingState,
                testContact2.MailingPostalCode,
                testContact2.Id
            );
        Test.stopTest();

        List<Contact> conList = [SELECT Id, Is_Mailing_Address_Verified__c FROM Contact WHERE Id = :testContact1.Id OR Id =: testContact2.Id];

        Assert.isTrue(conList[0].Is_Mailing_Address_Verified__c, 'It should be true');
        Assert.isTrue(conList[1].Is_Mailing_Address_Verified__c, 'It should be true');
    }
}