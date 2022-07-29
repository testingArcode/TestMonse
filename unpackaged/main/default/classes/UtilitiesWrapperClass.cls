/**
 * @author Arcode.
 * @description This class serves as a wrapper for Utilities feature.
 * <p /><p /> 
 */
global class UtilitiesWrapperClass {

	//Public variables.
	@AuraEnabled
	public Boolean boolEncrypt {get; set;}
	@AuraEnabled
	public Boolean boolEnvironmentSpecific {get; set;}
	@AuraEnabled
	public String strText {get; set;}
}