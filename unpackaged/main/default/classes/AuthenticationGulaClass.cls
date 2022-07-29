/**
 * @author Arcode.
 * @description This class executes the operations related to the Authentication Services.
 * <p /><p /> 
 */
public without sharing class AuthenticationGulaClass {
  
	/**
     * This method retrieves the User data, using an Authentication Service.
	 * 
	 * @param objRequest Request.
     * @return TransactionWrapperClass.
     */
	@AuraEnabled(cacheable = false)
    public static UserGulaWrapperClass getUserData(AuthenticationGulaWrapperClass objRequest) {
		TransactionWrapperClass objCalloutResponse;
		FacebookGulaWrapperClass objFacebookData;
		UserGulaWrapperClass objResponse = new UserGulaWrapperClass();
		TransactionWrapperClass objCalloutRequest = new TransactionWrapperClass();
		
		//We predefine the response.
		objResponse.boolSuccess = false;
		System.debug(objRequest);
		
		//Now, we check if we received a correct request.
		if(objRequest != null) {

			//Now we confirm we received the token of the user.
			if(String.isNotBlank(objRequest.strToken)) {

				//Now we confirm we received a service type.
				if(String.isNotBlank(objRequest.strType)) {

					//Now we check the Service type, so we execute the corresponding callout.
					if(objRequest.strType == 'GitHub') {
						
						//Now we do the callout to Facebook, to get the User data.
						objCalloutRequest.strLabel = 'GitHub Get User Data';
						objCalloutRequest.mapPathVariables = new Map<String, String>();
						objCalloutRequest.mapPathVariables.put('token', objRequest.strToken);
						objCalloutResponse = TransactionClass.callout(objCalloutRequest);

						//Now we verify the response.
						if(objCalloutResponse.boolHasException) {
							objResponse.intErrorCode = 5;
						} else if(objCalloutResponse.intStatusCode != 200) {
							objResponse.intErrorCode = objCalloutResponse.intStatusCode;
						} else {

							//The response is valid, so we send back the data.
							objFacebookData = (FacebookGulaWrapperClass) JSON.deserialize(objCalloutResponse.strBody, FacebookGulaWrapperClass.class);
							objResponse.strIdentifier = objFacebookData.id;
							objResponse.strPublicName = objFacebookData.name;
							objResponse.boolSuccess = true;
						}
					} else {

						//No service type defined, so we set the error.
						objResponse.intErrorCode = 4;
					}
				} else {
					objResponse.intErrorCode = 3;
				}
			} else {
				objResponse.intErrorCode = 2;
			}
		} else {
			objResponse.intErrorCode = 1;
		}

		//Now we return the results.
		return objResponse;
    }
  
	/**
     * This method removes the permissions of Gula app on the given user, on the Authentication Service provider.
	 * 
	 * @param objRequest Request.
     * @return TransactionWrapperClass.
     */
    public static UserGulaWrapperClass getAppAuthorizationRemoved(AuthenticationGulaWrapperClass objRequest) {
		TransactionWrapperClass objCalloutResponse;
		FacebookGulaWrapperClass objFacebookData;
		UserGulaWrapperClass objResponse = new UserGulaWrapperClass();
		TransactionWrapperClass objCalloutRequest = new TransactionWrapperClass();

		//We predefine the response.
		objResponse.boolSuccess = false;
		
		//Now, we check if we received a correct request.
		if(objRequest != null) {

			//Now we confirm we received the token of the user.
			if(String.isNotBlank(objRequest.strToken)) {

				//Now we confirm we received a service type.
				if(String.isNotBlank(objRequest.strType)) {

					//Now we check the Service type, so we execute the corresponding callout.
					if(objRequest.strType == 'GitHub') {
						
						//Now we do the callout to Facebook, to get the permissions removed.
						objCalloutRequest.boolExecuteInFuture = true;
						objCalloutRequest.strLabel = 'GitHub Unauthorize App';
						objCalloutRequest.mapPathVariables = new Map<String, String>();
						objCalloutRequest.mapPathVariables.put('token', objRequest.strToken);
						objCalloutResponse = TransactionClass.callout(objCalloutRequest);
						objResponse.boolSuccess = true;
					} else {

						//No service type defined, so we set the error.
						objResponse.intErrorCode = 41;
					}
				} else {
					objResponse.intErrorCode = 42;
				}
			} else {
				objResponse.intErrorCode = 43;
			}
		} else {
			objResponse.intErrorCode = 44;
		}

		//Now we return the results.
		return objResponse;
    }
}