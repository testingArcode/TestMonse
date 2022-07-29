/**
 * @author Arcode.
 * @description This class serves as a wrapper for Pictures feature.
 * <p /><p /> 
 */
global virtual class PictureGulaWrapper extends ResponseGulaWrapper {

	//Public variables.
	@AuraEnabled
	public List<String> lstURLs {get; set;}
}