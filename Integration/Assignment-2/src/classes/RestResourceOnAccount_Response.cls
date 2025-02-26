/**
 * Purpose        : This class serves as a response wrapper for the RESTful API endpoints in the RestResourceOnAccount class.
 * 
 * Created by     : Sajal Mittal
 * 
 * Created Date   : 24-02-2025
 * 
 * Revision Logs  : V_1.0 - Created
 **/
global class RestResourceOnAccount_Response {
    global String status;
    global String message;
    global Map<String, object> data;    
}