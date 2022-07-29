/**
 * @author Arcode.
 * @description This class serves as ping service, to keep the integration user session alive.
 * <p /><p /> 
 */
@RestResource(urlMapping='/gula/ping/*')
global without sharing class PingGulaService {

	/**
     * Get method, which retrieves the ping.
	 * 
     * @return TransactionWrapperClass.
     */
	@HttpGet
    global static Boolean ping() {
		return true;
    }
}