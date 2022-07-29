/**
 * @author Arcode.
 * @description This class provides developers with different utility methods.
 * <p /><p /> 
 */
public class UtilitiesClass {

    /**
     * This method generates a unique id for the transaction.
     *
     * @return String.
     */
    public static String getGUID() {
        Blob objHash = Crypto.generateDigest('MD5', Blob.valueOf('1000' + Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS')));
        String strResult = EncodingUtil.convertToHex(objHash);
        strResult = Userinfo.getUserId() + DateTime.now() + ':' + DateTime.now().millisecond() + strResult + Integer.valueof(Math.random() * 10000);
        strResult = strResult.replace(' ', '');
        return strResult;
    }

    /**
     * This method generates a unique id for the transaction.
     *
     * @return String.
     */
    public static String getStringEncryptedDecrypted(UtilitiesWrapperClass objRequest) {
        String strResult = '';
		String strEncryptionKey = '';
		String strEncryptionAlgorithm = 'AES256';
		Configuration__mdt objConfiguration = getEnvironmentConfiguration();

		//First we generate the encryption key.
		if(objRequest.boolEnvironmentSpecific != null && objRequest.boolEnvironmentSpecific) {
			strEncryptionKey = UserInfo.getOrganizationId();
		}
		strEncryptionKey += objConfiguration.EncryptionKey__c;

		//Now we define if we need to encrypt or decrypt the text(s).
		if(objRequest.boolEncrypt) {
			strResult = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV(strEncryptionAlgorithm, getKeyGenerated(strEncryptionKey), Blob.valueOf(objRequest.strText)));
		} else {
			strResult = Crypto.decryptWithManagedIV(strEncryptionAlgorithm, getKeyGenerated(strEncryptionKey), EncodingUtil.base64Decode(objRequest.strText)).toString();
		}
		return strResult;
    }
    
    /**
     * Returs the latest active environment configuration.
	 * 
     * @return Configuration__mdt.
     */
    public static Configuration__mdt getEnvironmentConfiguration() {
		Configuration__mdt objResult;
		for(Configuration__mdt objExistinRecord : [SELECT EncryptionKey__c, EncryptAttachmentLogs__c, EncryptTransactionFields__c, LoggingLevel__c FROM 
				Configuration__mdt WHERE Active__c = TRUE LIMIT 1]) {
			objResult = objExistinRecord;
		}
		if(objResult == null) {
			objResult = new Configuration__mdt();
			objResult.EncryptionKey__c = 'Default';
			objResult.EncryptAttachmentLogs__c = true;
			objResult.EncryptTransactionFields__c = true;
			objResult.LoggingLevel__c = 'All';
		}
        return objResult;
    }
    
    /**
     * Creates the corresponding key to encrypt / decrypt data.
     *
     * @param strKey Seed key to be prepared.
     * @return Blob.
     */
    private static Blob getKeyGenerated(String strKey) {
        String strUpdatedKey = strKey;
        if(String.isNotBlank(strUpdatedKey)) {
            if(strUpdatedKey.length() > 32) {
                strUpdatedKey = strUpdatedKey.substring(0, 31);
            } else {
                while(strUpdatedKey.length() < 32) {
                    strUpdatedKey = strUpdatedKey + '0';
                }
            }
        }
        return Blob.valueOf(strUpdatedKey);
    }
}