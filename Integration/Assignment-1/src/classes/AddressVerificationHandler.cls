/** 
 * Purpose          :   Class to verify mailing addresses of contact using SmartyStreet Api implementing future method.
 * 
 * Created by       :   Sajal Mittal
 * 
 * Created Date     :   20-02-2025
 * 
 * Rivision Logs    :   V_1.0 - Created
 * 
**/
public with sharing class AddressVerificationHandler {
    /**
     * Method Name  :   verifyAddress
     * 
     * Created by   :   Sajal Mittal
     * 
     * Purpose      :   Future method to verify Mailing Address of Contact and to update 
     *                  the 'Is_Mailing_Address_Verified__c' field on the Contact record 
     *                  based on the verification result. 
     * 
     * return       :   void
     * 
     * param        :   String street, String city, String state, String postalCode, Id id
    **/
    @future(callout=true)
    public static void verifyAddress(String street, String city, String state, String postalCode, Id id) {
        String mailingStreet  = EncodingUtil.urlEncode(street!=null?street:'', 'UTF-8');
        String mailingCity = EncodingUtil.urlEncode(city!=null?city:'', 'UTF-8');
        String mailingState = EncodingUtil.urlEncode(state!=null?state:'', 'UTF-8');
        String mailingPostalCode = EncodingUtil.urlEncode(postalCode!=null?postalCode:'', 'UTF-8');
        Id conId = id;
        Boolean isValid = false;

        HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        String URL = '';
        if(String.isBlank(mailingPostalCode)) {
            URL = 'https://us-street.api.smarty.com/street-address?' + 
                    'auth-id=668b777a-914c-432c-e4b2-4d0482b86f81&' +
                    'auth-token=8GRKWWB5TQ0ht777aIQQ&' +
                    'street=' + mailingStreet + '&' +
                    'city=' + mailingCity + '&' +
                    'state='+ mailingState + '&' +
                    'candidates=10';
        } else {
            URL = 'https://us-street.api.smarty.com/street-address?' + 
                    'auth-id=668b777a-914c-432c-e4b2-4d0482b86f81&' +
                    'auth-token=8GRKWWB5TQ0ht777aIQQ&' +
                    'street=' + mailingStreet + '&' +
                    'zipcode=' + mailingPostalCode + '&' +
                    'candidates=10';
        }
        if(String.isNotBlank(URL)) {
            req.setEndpoint(URL);
            req.setMethod('GET');
            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200) {
                List<Object> responseList = (List<Object>) JSON.deserializeUntyped(res.getBody());
                if(responseList.size() > 0) {
                    Map<String, Object> firstResult = (Map<String, Object>) responseList[0];
                    if(firstResult.containsKey('analysis')) {
                        Map<String, object> analysisMap = (Map<String, Object>) firstResult.get('analysis');
                        if(analysisMap.containsKey('dpv_match_code')) {
                            String dpvMatchCode = (String) analysisMap.get('dpv_match_code');
                            if(dpvMatchCode == 'Y') {
                                isValid = true;
                            }
                        }
                    }
                }
            }
        }

        if(conId != null) {
            Contact con = new Contact(Id = conId, Is_Mailing_Address_Verified__c = isValid);
            update con;
        }
    }
}