/**
 * @author Arcode.
 * @description This class provides developers with different utility methods for Gula App.
 * <p /><p /> 
 */
public class UtilityGulaClass {

    /**
     * This method creates an error record, if needed.
     *
     * @param boolSuccess Indicates if the original transaction was a success
	 * @param intErrorCode Error code.
	 * @param strUserId User Id that caused the error.
     */
	@future
    public static void getErrorSaved(Boolean boolSuccess, Integer intErrorCode, String strUserId) {
        GulaError__c objError = new GulaError__c();

		//Only if indicated, we store the record.
		if(boolSuccess == null || !boolSuccess) {
			objError.Code__c = intErrorCode;
			if(String.isNotBlank(strUserId)) {
				objError.User__c = strUserId;
			}
			insert objError;
		}
    }
}