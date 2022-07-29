/**
 * @author Arcode.
 * @description This class serves as a wrapper for Authentication Service feature.
 * <p /><p /> 
 */
global virtual class AuthenticationGulaWrapperClass extends ResponseGulaWrapper {

	//Public variables.
	@AuraEnabled
	public String strType {get; set;}
	@AuraEnabled
	public String strToken {get; set;}
	@AuraEnabled
	public String strIdentifier {get; set;}
}