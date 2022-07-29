/**
 * @author Arcode.
 * @description This class helps developers to log transactions (callouts, DMLs and Exceptions).
 * <p /><p /> 
 */
global without sharing class TransactionClass {

	//Public variables.
	public static final Boolean BOOLEAN_ENCRYPT_ALL_DATA = UtilitiesClass.getEnvironmentConfiguration().EncryptTransactionFields__c;
	public static final String STRING_LOGGING_LEVEL = UtilitiesClass.getEnvironmentConfiguration().LoggingLevel__c;
	public static final Id ID_RECORD_TYPE_CALLOUT = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Callout').getRecordTypeId();
	public static final Id ID_RECORD_TYPE_EXCEPTION = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Exception').getRecordTypeId();
    public static String strCode;

	/**
     * This method executes a callout.
     * 
     * @param objData Request data.
     * @return TransactionWrapperClass.
     */
    @AuraEnabled(cacheable = false)
	public static TransactionWrapperClass callout(TransactionWrapperClass objData) {

		//First we check if we received a request.
		if(objData != null) {

			//Now we get the endpoint.
			objData = getEndpoint(objData);

			//Now get replace the path variables.
			objData = getPathVariablesReplaced(objData);

			//Now we execute the callout.
			if(objData.boolExecuteInFuture == null || !objData.boolExecuteInFuture) {
				objData = executeCallout(objData);
			} else {
				executeCalloutInFuture(JSON.serialize(objData, true));
			}
		}

		//Finally, we return the result.
		return objData;
	}

	/**
     * This method returns the endpoint data.
     * 
     * @param objData Request data.
     * @return TransactionWrapperClass.
     */
	@AuraEnabled(cacheable = false)
	public static TransactionWrapperClass getEndpoint(TransactionWrapperClass objData) {
		String strLabel = objData.strLabel;
		String strEnvironmentId = UserInfo.getOrganizationId();
		String strEnvironmentId15Digits = strEnvironmentId.substring(0, 15);
		Map<String, String> mapHeaders;

		//Now we query the endpoint.
		if(objData != null && String.isNotBlank(strLabel)) {
			
			for(Endpoint__mdt objEndpoint : [SELECT Credential__r.ClientId__c, Credential__r.ClientSecret__c, URL__c, Method__c, RedirectURI__c, Headers__c FROM Endpoint__mdt WHERE 
					Label = :strLabel AND Active__c = TRUE AND (Environment__r.Id__c = :strEnvironmentId OR Environment__r.Id__c = :strEnvironmentId15Digits) AND 
					Environment__r.Active__c = TRUE LIMIT 1]) {

				//We set the credentials, if any.
				if(objEndpoint.Credential__r != null) {
					objData.strClientId = objEndpoint.Credential__r.ClientId__c;
					objData.strClientSecret = objEndpoint.Credential__r.ClientSecret__c;
				}
				
				//Now we set the rest of the properties.
				objData.strEndpoint = objEndpoint.URL__c;
				objData.strMethod = objEndpoint.Method__c;
				objData.strRedirectURI = objEndpoint.RedirectURI__c;

				//Now we check any possible custom headers, stores on the Endpoint record.
				if(String.isNotBlank(objEndpoint.Headers__c)) {
					if(objData.mapHeaders == null) {
						objData.mapHeaders = new Map<String, String>();
					}
					mapHeaders = (Map<String, String>) JSON.deserialize(objEndpoint.Headers__c, Map<String, String>.class);
					for(String strKey : mapHeaders.keySet()) {
						objData.mapHeaders.put(strKey, mapHeaders.get(strKey));
					}
				}
			}
		}

		return objData;
	}

	/**
     * This method replaces the path variables in the URL.
     * 
     * @param objData Request data.
     * @return TransactionWrapperClass.
     */
	@AuraEnabled(cacheable = false)
	public static TransactionWrapperClass getPathVariablesReplaced(TransactionWrapperClass objData) {
		String strValue;

		//If we require to replace the path variables.
		if(objData != null && objData.mapPathVariables != null && String.isNotBlank(objData.strEndpoint)) {
			for(String strPathVariable : objData.mapPathVariables.keySet()) {
				
				//If we have an endpoint.
				objData.strEndpoint = objData.strEndpoint.replace('{{' + strPathVariable + '}}', objData.mapPathVariables.get(strPathVariable));
			}
		}

		//If we require to replace variables on the headers [Client Id, Client Secret]
		if(objData.mapHeaders != null) {
			for(String strKey : objData.mapHeaders.keySet()) {
				strValue = objData.mapHeaders.get(strKey);

				//We look for client id.
				if(strValue.contains('{{ClientId}}')) {
					strValue = strValue.replace('{{ClientId}}', objData.strClientId);
				}

				//We look for client secret.
				if(strValue.contains('{{ClientSecret}}')) {
					strValue = strValue.replace('{{ClientSecret}}', objData.strClientSecret);
				}

				//We save the changes.
				objData.mapHeaders.put(strKey, strValue);
			}
		}
		return objData;
	}

	/**
     * This method executes a callout based on the provided data, in a future method.
     * 
     * @param strSerializedData Request data.
     */
	@future(callout = true)
	public static void executeCalloutInFuture(String strSerializedData) {
		if(String.isNotBlank(strSerializedData)) {
			executeCallout((TransactionWrapperClass) JSON.deserialize(strSerializedData, TransactionWrapperClass.class));
		}
	}

	/**
     * This method executes a callout based on the provided data.
     * 
     * @param objData Request data.
     * @return TransactionWrapperClass.
     */
	@AuraEnabled(cacheable = false)
	public static TransactionWrapperClass executeCallout(TransactionWrapperClass objData) {
        Http objHttp = new Http();
        HttpRequest objHttpRequest = new HttpRequest();
        HttpResponse objResponse;
		Transaction__c objTransaction = new Transaction__c();
		TransactionWrapperClass objResult = new TransactionWrapperClass();

		//We use Try-Catch-Finally.
		try {
			objResult.boolHasException = false;
			objTransaction.RecordTypeId = ID_RECORD_TYPE_CALLOUT;

			//If we have the required data.
			if(objData != null) {
				
				//If we have headers to add.
				if(objData.mapHeaders != null) {
					for(String strKey : objData.mapHeaders.keySet()) {
					
						//If we have an endpoint.
						objHttpRequest.setHeader(strKey, objData.mapHeaders.get(strKey));
					}
					objTransaction.Headers__c = getStringEncrypted(JSON.serialize(objData.mapHeaders, true));
				}

				//If the label is 'GitHub Get User Data'.
				if(objData.strLabel == 'GitHub Get User Data') {
				objData.strBody = ('client_id=' + objData.strClientId + '&client_secret=' + objData.strClientSecret + '&code=' + objData.strCode + '&redirect_uri=' 
				+ objData.strRedirectURI);
				} else if(objData.strLabel == 'GitHub Create Pull Request') {
					String payload = JSON.serialize(new Map<String,Object>{
						'title' => 'TestRichard',
						'body' => 'new Pull request!',
						'head' => 'TestRichard',
						'base' => 'master'
					});
					objData.strBody = payload;

				//If the label is 'GitHub Create Commit'.	
				} else if(objData.strLabel == 'GitHub Create Commit') {
					Blob value = Blob.valueOf('HolaaaaMonse');
					String content = EncodingUtil.base64Encode(value);
					String payload = JSON.serialize(new Map<String,Object>{
						'message' => 'Ready',
						'content' => content,
						'name' => 'notes',
						'sha' => '242aff811a42af61616cd2c97d99f35363659364',
						'branch' => 'master'
					});
					objData.strBody = payload;
				}

				//If we have a body.
				if(String.isNotBlank(objData.strBody)) {
					objHttpRequest.setBody(objData.strBody);
					objTransaction.Request__c = getStringEncrypted(objData.strBody);
					objTransaction.BodyBlob__c = false;
				} else if(objData.objBody != null) {
					objHttpRequest.setBodyAsBlob(objData.objBody);
					objTransaction.Request__c = getStringEncrypted(objData.objBody.toString());
					objTransaction.BodyBlob__c = true;
				}

				//If we have a method.
				if(String.isNotBlank(objData.strMethod)) {
					objData.strMethod = objData.strMethod.toUpperCase();
					objHttpRequest.setMethod(objData.strMethod);
					objTransaction.Method__c = objData.strMethod;
				}

				//If we have an endpoint.
				if(String.isNotBlank(objData.strEndpoint)) {
					objHttpRequest.setEndpoint(objData.strEndpoint);
					objTransaction.Endpoint__c = getStringEncrypted(objData.strEndpoint);
				}

				//Now we execute the callout.
				objResponse = objHttp.send(objHttpRequest);

				//Now we extract the response.
				objResult.intStatusCode = objResponse.getStatusCode();
				objResult.strBody = objResponse.getBody();
				objResult.objBody = objResponse.getBodyAsBlob();
				objResult.mapHeaders = new Map<String, String>();
				for(String strHeader : objResponse.getHeaderKeys()) {
					objResult.mapHeaders.put(strHeader, objResponse.getHeader(strHeader));
				}

				//Now we set the Transaction updates.
				objTransaction.IsEncrypted__c = BOOLEAN_ENCRYPT_ALL_DATA;
				objTransaction.ResponseCode__c = objResult.intStatusCode;
				objTransaction.ResponseHeaders__c = getStringEncrypted(JSON.serialize(objResult.mapHeaders, true));
				if(String.isNotBlank(objResult.strBody)) {
					objTransaction.Response__c = getStringEncrypted(objResult.strBody);
					objTransaction.ResponseBodyBlob__c = false;
				} else {
					objTransaction.Response__c = getStringEncrypted(objResult.objBody.toString());
					objTransaction.ResponseBodyBlob__c = true;
				}
			}
		} catch(Exception objException) {
			
			//Now we process the exception.
			objResult.boolHasException = true;
			objResult.objException = objException;
			objTransaction.RelatedTransaction__r = getExceptionProcessed(objException, false);
		} finally {

			//Now we update the Transaction (Callout) record.
			if(STRING_LOGGING_LEVEL == 'All' || objTransaction.ResponseCode__c < 200 || objTransaction.ResponseCode__c > 299) {
				objResult.strCorrelationId = getTransactionRecordEnqueued(objTransaction);
			}
		}

		//Now we return the result.
		return objResult;
	}

    /**
     * This method enqueues the transaction record upsertion.
	 * 
	 * @param objTransaction Transaction record to be saved.
	 * @return String.
     */
    public static String getTransactionRecordEnqueued(Transaction__c objTransaction) {
		String strCorrelationId;
		if(objTransaction != null) {

			//We generate the GUID and send it back to the caller, if the transaction is a Callout.
			if(objTransaction.RecordTypeId == ID_RECORD_TYPE_CALLOUT) {
				strCorrelationId = UtilitiesClass.getGUID();
				objTransaction.CorrelationId__c = strCorrelationId;
			}

			//Now we enqueue the job.
			System.enqueueJob(new TransactionQueueableClass(objTransaction));
		}
		return strCorrelationId;
	}

    /**
     * This method creates the transaction record.
	 * 
	 * @param objTransaction Transaction record to be saved.
	 * @return Transaction__c.
     */
    public static Transaction__c getTransactionRecordUpserted(Transaction__c objTransaction) {
		Integer intLimit = 131072;
		Attachment objAttachment;
		Transaction__c objChildTransaction;
		UtilitiesWrapperClass objRequest = new UtilitiesWrapperClass();
		List<Attachment> lstAttachments = new List<Attachment>();

		//First we make sure we received something to insert.
		if(objTransaction != null) {

			//First we remove child records, if any.
			if(objTransaction.RelatedTransaction__r != null) {
				objChildTransaction = objTransaction.RelatedTransaction__r;
				objTransaction.RelatedTransaction__r = null;
			}

			//Now we check if any of the text areas are not enough (space), in which case we store the data as Attachments.
			if(String.isNotBlank(objTransaction.Endpoint__c) && objTransaction.Endpoint__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'Endpoint__c', objTransaction.Endpoint__c));
			}
			if(String.isNotBlank(objTransaction.Headers__c) && objTransaction.Headers__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'Headers__c', objTransaction.Headers__c));
			}
			if(String.isNotBlank(objTransaction.ResponseHeaders__c) && objTransaction.ResponseHeaders__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'ResponseHeaders__c', objTransaction.ResponseHeaders__c));
			}
			if(String.isNotBlank(objTransaction.Message__c) && objTransaction.Message__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'Message__c', objTransaction.Message__c));
			}
			if(String.isNotBlank(objTransaction.Request__c) && objTransaction.Request__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'Request__c', objTransaction.Request__c));
			}
			if(String.isNotBlank(objTransaction.Response__c) && objTransaction.Response__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'Response__c', objTransaction.Response__c));
			}
			if(String.isNotBlank(objTransaction.StackTrace__c) && objTransaction.StackTrace__c.length() > intLimit) {
				lstAttachments.add(getAttachmentPrepared(!objTransaction.IsEncrypted__c, 'StackTrace__c', objTransaction.StackTrace__c));
			}

			//Now we insert the transaction object.
			if(String.isNotBlank(objTransaction.CorrelationId__c)) {
				upsert objTransaction CorrelationId__c;
			} else if(objTransaction.Id != null) {
				update objTransaction;
			} else {

				//If the transaction is a Callout.
				if(objTransaction.RecordTypeId == ID_RECORD_TYPE_CALLOUT) {
					objTransaction.CorrelationId__c = UtilitiesClass.getGUID();
				}
				
				//Now we insert the record.
				insert objTransaction;
			}

			//If we have attachments to insert, we populate the parent ids.
			if(!lstAttachments.isEmpty()) {
				for(Attachment objAttachmentToInsert : lstAttachments) {
					objAttachmentToInsert.ParentId = objTransaction.Id;
				}
				insert lstAttachments;
			}

			//Now, we check if we received a related transaction, and we process it.
			if(objChildTransaction != null) {
				objChildTransaction.RelatedTransaction__c = objTransaction.Id;
				getTransactionRecordUpserted(objChildTransaction);
			}
		}
		return objTransaction;
    }

    /**
     * This method prepares an Attachment record with a predefined structure and encryption.
	 * 
	 * @param boolEncrypt Request data.
	 * @param strName File Name.
	 * @param strBody Attachment body.
     * @return Attachment.
     */
    public static Attachment getAttachmentPrepared(Boolean boolEncrypt, String strName, String strBody) {
		Attachment objAttachment = new Attachment();
		UtilitiesWrapperClass objRequest = new UtilitiesWrapperClass();

		//We check if we need to encrypt the content.
		if(boolEncrypt) {
			objRequest.boolEncrypt = true;
			objRequest.boolEnvironmentSpecific = true;
			objRequest.strText = strBody;
			objAttachment.Body = Blob.valueOf(UtilitiesClass.getStringEncryptedDecrypted(objRequest));
		} else {
			objAttachment.Body = Blob.valueOf(strBody);
		}

		//We set the name and return the attachment structure.
		objAttachment.Name = strName + '.arcode';
		return objAttachment;
    }

    /**
     * This method extracts the exception data and then throws the exception back to the caller.
	 * 
	 * @param objException Exception to be processed.
	 * @return Transaction__c.
     */
    public static Transaction__c getExceptionProcessed(Exception objException, Boolean boolImmediateInsert) {
		Transaction__c objTransaction = new Transaction__c();

		//First we check if we received the exception.
		if(objException != null) {
			objTransaction.RecordTypeId = ID_RECORD_TYPE_EXCEPTION;
			objTransaction.Message__c = objException.getMessage();
			objTransaction.StackTrace__c = objException.getStackTraceString();

			//If we want to insert the transaction.
			if(boolImmediateInsert != null && boolImmediateInsert) {
				getTransactionRecordEnqueued(objTransaction);
			}
		}
		return objTransaction;
	}

    /**
     * This method encrypts a string, if the global configuration requests it.
	 * 
	 * @param strText Text to be encrypted.
     * @return String.
     */
    public static String getStringEncrypted(String strText) {
		String strResult = strText;
		UtilitiesWrapperClass objRequest = new UtilitiesWrapperClass();
		//We check if we need to encrypt the content.
		if(BOOLEAN_ENCRYPT_ALL_DATA) {
			objRequest.boolEncrypt = true;
			objRequest.boolEnvironmentSpecific = true;
			objRequest.strText = strText;
			strResult = UtilitiesClass.getStringEncryptedDecrypted(objRequest);
		}
		return strResult;
    }
}