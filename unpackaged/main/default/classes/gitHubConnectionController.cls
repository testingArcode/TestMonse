/**
 * @author Arcode.
 * @description This class manages connections with GitHub.
 * <p /><p /> 
 */
public without sharing class gitHubConnectionController {
    
    //Public variables.
    public static String strClientId;
    public static String strAuthorizationUrl;
    public static String strScope;
    public static String strState;
    public static String strRedirectUri;
    public static String strCode;
    public static String strUrl;
    public static String strToken;
    
    /**
     * This method generates the authentication url.
     * @return get url for user authorization.
     */
    @AuraEnabled(cacheable = false)
    public static String getAuthentication() {
		String strEnvironmentId = UserInfo.getOrganizationId();
		String strEnvironmentId15Digits = strEnvironmentId.substring(0, 15);
        integrationApp__mdt objIntegrateApp = [SELECT ClientId__c, Scope__c, RedirectURI__c, State__c, AuthorizationURL__c FROM integrationApp__mdt];
        strRedirectUri = objIntegrateApp.RedirectURI__c;
        strState = objIntegrateApp.State__c;
        strAuthorizationUrl = objIntegrateApp.AuthorizationURL__c;
        strScope = objIntegrateApp.Scope__c;
        strClientId = objIntegrateApp.ClientId__c;
        strUrl = strAuthorizationUrl + '?scope=' + strScope + '&client_id=' + strClientId + '&redirect_uri=' + strRedirectUri + '&state=' + strState;
        return strUrl;
    }

    /**
     * This method generates and saves a token.
     */
    @AuraEnabled(cacheable = true)
    public static void getToken() {
        Boolean boolResult;
        String strResults;
        String strAccesToken = 'access_token=[a-zA-Z0-9_]{40}';
        TransactionWrapperClass objData = new TransactionWrapperClass();
        Matcher objMatcher;


        //We obtain code generated in authentication phase and assigned endpoint's label.
        objData.strCode = ApexPages.currentPage().getParameters().get('code');
        objData.strLabel = 'GitHub Get User Data';
        objData = TransactionClass.callout(objData);

        //We obtain only alphanumeric part from Access Token.
        objMatcher = Pattern.compile(strAccesToken).matcher(objData.strBody);
        boolResult = objMatcher.find();
 
        //If the Token exists, we save token.
        if(boolResult) {
            strResults = objMatcher.group(0).substring(13, 53);
    
            //We save Token in Token__c field.
            User objUser = [SELECT Id, Token__c FROM User WHERE Id = :UserInfo.getUserId()];
            objUser.Token__c = strResults;
            update objUser;
        }
    }

    /**
     * This method obtains the pulls from the GitHub user.
     * @return get the list of Pull Requests.
     */
    @AuraEnabled(cacheable = false)
    public static List<Object> getUserData(String strOperations) {
        String strResult;
        User objUser = [SELECT Token__c FROM User WHERE Id = :UserInfo.getUserId()];
        strToken = objUser.Token__c;
        AuthenticationGulaWrapperClass objRequest = new AuthenticationGulaWrapperClass();
        TransactionWrapperClass objData = new TransactionWrapperClass();
        TransactionWrapperClass objCalloutResponse;
		FacebookGulaWrapperClass objFacebookData;
		UserGulaWrapperClass objResponse = new UserGulaWrapperClass();
		TransactionWrapperClass objCalloutRequest = new TransactionWrapperClass();
        gitHubConnectionWrapperClass objList = new gitHubConnectionWrapperClass();
		objRequest.strType = 'GitHub';
        if(strOperations != null && strOperations != 'undefined' && strOperations != ''){
            switch on strOperations{
                when 'createPulls' {
                    objData.strLabel = 'GitHub Create Pull Request';
                }
                when 'viewPulls' {
                    objData.strLabel = 'GitHub Unauthorize App';
                }
                when 'createCommit' {
                    objData.strLabel = 'GitHub Create Commit';
                }
                when 'GitHub GitHub Unauthorize App' {
                    objData.strLabel = 'GitHub Unauthorize App';
                }
                when 'viewRepositories' {
                    objData.strLabel = 'GitHub Get Repositories';
                }
                when 'viewBranches' {
                    objData.strLabel = 'GitHub Get Branches';
                }
            }
        } 
        objData = TransactionClass.callout(objData);

		//We predefine the response.
		objResponse.boolSuccess = false;
		
		//Now, we check if we received a correct request.
		if(objRequest != null) {

			//Now we confirm we received the token of the user.
			if(String.isNotBlank(strToken)) {

				//Now we confirm we received a service type.
				if(String.isNotBlank(objRequest.strType)) {

					//Now we check the Service type, so we execute the corresponding callout.
					if(objRequest.strType == 'GitHub') {

                        //Now we do the callout to Facebook, to get the User data.
						objCalloutRequest.strLabel = objData.strLabel;
                        objCalloutRequest.mapPathVariables = new Map<String, String>();
						objCalloutRequest.mapPathVariables.put('token', strToken);
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
        //Now we return the list of results.
        System.debug(objData.strLabel);
        List<Object> lstPulls = (List<Object>)JSON.deserializeUntyped(objData.strBody);
        return lstPulls;
    }

    /**
     * This method create pull request.
     * 
     */
    @AuraEnabled(cacheable = false)
    public static void createPullRequest() {
        String strOperations = 'createPulls';
        getUserData(strOperations);
    }

    /**
     * This method create commit.
     * 
     */
    @AuraEnabled(cacheable = false)
    public static void createCommit() {
        String strOperations = 'createCommit';
        getUserData(strOperations);
    }

    /**
     * This method obtains pull request.
     * @return get list of pull request.
     */
    @AuraEnabled(cacheable = false)
    public static List<Object> getPullRequest() {
        String strOperations = 'viewPulls';
        List<Object> lstPulls = getUserData(strOperations);
        return lstPulls;
    }

    /**
     * This method obtains repositories.
     * @return get list of repositories.
     */
    @AuraEnabled(cacheable = false)
    public static List<Object> getRepositories() {
        String strOperations = 'viewRepositories';
        List<Object> lstPulls = getUserData(strOperations);
        return lstPulls;
    }

    /**
     * This method obtains repositories.
     * @return get user's token.
     */
    @AuraEnabled(cacheable = false)
    public static List<Object> getBranches() {
        String strOperations = 'viewBranches';
        List<Object> lstPulls = getUserData(strOperations);
        return lstPulls;
    }

    /**
     * This method obtains the token Id.
     * @return get user's token.
     */
    @AuraEnabled(cacheable = false)
    public static String getTokenId() {
        User objUser = [SELECT Id, Token__c FROM User WHERE Id = :UserInfo.getUserId()];
        strToken = objUser.Token__c;
        return strToken;
    }

}