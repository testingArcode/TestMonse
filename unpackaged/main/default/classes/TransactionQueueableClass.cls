/**
 * @author Arcode.
 * @description This class runs the upsertion of Transaction records in an asynchronous mode.
 * <p /><p /> 
 */
global without sharing class TransactionQueueableClass implements Queueable {

	//Public variables.
	public Transaction__c objTransaction;

    /**
     * Constructor of the class.
     *
     * @param objTransaction Transaction record to be upserted.
     */
    public TransactionQueueableClass(Transaction__c objTransaction) {
		this.objTransaction = objTransaction;
	}

    /**
     * Method that processes the Transaction record.
     *
     * @param objContext Execution context.
     */
    public void execute(QueueableContext objContext) {
		TransactionClass.getTransactionRecordUpserted(objTransaction);
	}
}