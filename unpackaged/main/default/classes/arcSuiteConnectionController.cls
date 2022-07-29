/**
 * @author Arcode.
 * @description This class serves as a controller for Arcode Suite Controller.
 * <p /><p /> 
 */
public with sharing class arcSuiteConnectionController {

    private String strClientId;
    private String strClientSecret;
    private String strAccessTokenUrl;
    private String strAuthorizationUrl;
    private String strScope;
    private String strState;
    private String strUserInfoUrl;
    private String strRedirectUri;
    private String strCode;
    public String strUrl {get; set;}
    public String strToken { get; set;}
    public String strRepositories;
    
        /**
     * This method returns the help text for the form fields.
     */
    public void getAuthentication() {
        strClientId = 'ef4d84387f76e7af6d66';
        strScope = 'gist';
        strRedirectUri = 'https://arcode--monsedev--c.visualforce.com/apex/succesLoginPageGitHub';
        strState = 'state';
        strAuthorizationUrl = 'https://github.com/login/oauth/authorize';
        strCode = ApexPages.currentPage().getParameters().get('code');
        strUrl = strAuthorizationUrl + '?scope='+ strScope +'&client_id=' + strClientId + '&redirect_uri=' + strRedirectUri +'&state='+ strState;
    }

    /**
     * This method generates and saves a token.
     */
    public void getToken() {
        Boolean boolResult;
        String strRegex = 'access_token=[a-zA-Z0-9_]{40}';
        strCode = ApexPages.currentPage().getParameters().get('code');
        strClientId = 'ef4d84387f76e7af6d66';
        strClientSecret= '064f883ee558e11b5c84ded4ec546fd0ceabcee1';
        strScope = 'gist';
        strRedirectUri = 'https://arcode--monsedev--c.visualforce.com/apex/succesLoginPageGitHub';
        strState = 'state';
        strAuthorizationUrl = 'https://github.com/login/oauth/authorize';
        Matcher objMatcher;
        HttpRequest objRequestToken = new HttpRequest();
        Http objHttpToken = new Http();
        HTTPResponse objResponseToken = new HTTPResponse();

        //We generate access_token.
        objRequestToken.setBody('client_id=' + strClientId + '&client_secret=' + strClientSecret + '&code=' + strCode + '&redirect_uri=' + strRedirectUri + '&state=' + strState);
        objRequestToken.setCompressed(false);
        objRequestToken.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        objRequestToken.setEndpoint('https://github.com/login/oauth/access_token');
        objRequestToken.setMethod('POST');
        objResponseToken = objHttpToken.send(objRequestToken);
        strToken = objResponseToken.getBody();

        //We obtain only alphanumeric token.
        objMatcher = Pattern.compile(strRegex).matcher(strToken);
        boolResult = objMatcher.find();

        //If the token exists, we save token.
        if(boolResult) {
            strToken = objMatcher.group(0);
            strToken = strToken.substring(13,53);
    
            //Save token in Token__c field.
            User objUser = [SELECT Id, Token__c FROM User WHERE Id = :UserInfo.getUserId()];
            objUser.Token__c = strToken;
            update objUser;
        }
    }

    /**
     * This method connects with api of GitHub and obtains repositories.
     */
    public void getApi() {
        HttpRequest objRequestApi = new HttpRequest();
        HTTP objHttpRepositories = new HTTP();
        HttpRequest objRequestRepositories = new HttpRequest();
        Http objHttpApi = new Http();
        HTTPResponse objResponseRepositories;
        HTTPResponse objResponseApi;
        User objUser = [SELECT Token__c FROM User WHERE Id = :UserInfo.getUserId()];

        //We connect with GitHub api.
        objRequestApi.setEndpoint('https://api.github.com/');
        objRequestApi.setHeader('Authorization','objUser');
        objRequestApi.setMethod('GET');
        objResponseApi = objHttpApi.send(objRequestApi);

        //We obtain the user's repositories.
        objRequestRepositories.setEndpoint('https://api.github.com/users/'+'MonsePedroza28'+'/repos');
        objRequestRepositories.setHeader('Authorization', 'objUser');
        objRequestRepositories.setmethod('GET');
        objResponseRepositories = objHttpRepositories.send(objRequestRepositories);
        strRepositories = objResponseRepositories.getBody();
    }

    /**
     * This method obtains the branches from the GitHub user.
     */
    public void getBranch() {
        String strJsonS;
        HttpRequest objRequestBranch = new HttpRequest();
        HTTP objHttpBranch = new HTTP();
        User objUser = [SELECT Token__c FROM User WHERE Id = :UserInfo.getUserId()];
        JSONGenerator objGeneration;
        HTTPResponse objResponseBranch;
        objRequestBranch.setEndpoint('https://github.com'+'MonsePedroza28'+'/+GitConnection+/');
        objRequestBranch.setHeader('Authorization','objUser');
        System.debug('objUser');
        objRequestBranch.setmethod('POST');
        objGeneration = JSON.createGenerator(true);
        objGeneration.writeStartObject();
        objGeneration.writeStringField('title','GitConnection');
        System.debug('Hola');
        objGeneration.writeStringField('head','GitConnection');
        objGeneration.writeStringField('base','GitConnection');
        objGeneration.writeEndObject();
        strJsonS = objGeneration.getAsString();
        System.debug(strJsonS);

        objRequestBranch.setBody(strJsonS);
        objResponseBranch = objHttpBranch.send(objRequestBranch);
    }
}