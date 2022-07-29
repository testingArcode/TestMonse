/**
 * @author Arcode.
 * @description This class serves as a generic wrapper for all the service responses.
 * <p /><p /> 
 */
global virtual class ResponseGulaWrapper {

	//Public variables.
	@AuraEnabled
	public Boolean boolSuccess {get; set;}
	@AuraEnabled
	public Integer intErrorCode {get; set;}
}