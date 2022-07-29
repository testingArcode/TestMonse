/**
 * @author Arcode.
 * @description This class serves as a Provider wrapper class.
 * <p /><p /> 
 */
global virtual class ProviderGulaWrapper extends UserGulaWrapperClass {

	//Public variables.
	@AuraEnabled
	public Boolean boolIsAvailable {get; set;}
	@AuraEnabled
	public Double dblLatitude {get; set;}
	@AuraEnabled
	public Double dblLongitude {get; set;}
}