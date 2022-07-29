/**
 * @author Arcode.
 * @description This schedulable class executes an HTTP call to the ping service, to make sure the session stays aliv.
 * <p /><p /> 
 * System.schedule('Gula Ping Miday', '0 0 11 * * ?', new KeepSessionAliveGulaSchedule());
 * System.schedule('Gula Ping EOD', '0 0 23 * * ?', new KeepSessionAliveGulaSchedule());
 */
global class KeepSessionAliveGulaSchedule implements Schedulable {

	/**
     * This method gets executed when the schedulable job starts.
	 * 
     * @param objContext Schedulable context.
     */
	global void execute(SchedulableContext objContext) {
		
		//Here we do the callout.
		TransactionWrapperClass objData = new TransactionWrapperClass();
		objData.boolExecuteInFuture = true;
		objData.strLabel = 'Ping';
		TransactionClass.callout(objData);
	}
}