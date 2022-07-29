/**
 * @author Arcode.
 * @description This class serves as a wrapper for User data.
 * <p /><p /> 
 */
global virtual class UserGulaWrapperClass extends AuthenticationGulaWrapperClass {

	//Public variables.
	@AuraEnabled
	public Boolean boolAlreadyExists {get; set;}
	@AuraEnabled
	public Boolean boolActiveGPSTracking {get; set;}
	@AuraEnabled
	public Boolean boolAcceptedTermsAndConditions {get; set;}
	@AuraEnabled
	public Double dblMaximumPrice {get; set;}
	@AuraEnabled
	public Double dblMinimumPrice {get; set;}
	@AuraEnabled
	public String strCurrency {get; set;}
	@AuraEnabled
	public String strPublicName {get; set;}
	@AuraEnabled
	public List<String> lstCategories {get; set;}
	@AuraEnabled
	public List<Object> lstPulls {get; set;}
	@AuraEnabled
	public List<String> lstCurrencies {
		get {
			List<String> lstValues = new List<String>();
			for(Schema.PicklistEntry objPicklistValue : User__c.Currency__c.getDescribe().getPicklistValues()) {
				lstValues.add(objPicklistValue.getLabel());
			}     
			return lstValues;
		}
	}
}