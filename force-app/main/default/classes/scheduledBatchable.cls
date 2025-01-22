global class scheduledBatchable implements Schedulable {
    global void execute(SchedulableContext sc) {
        Batch_DailyTerminationDate b = new Batch_DailyTerminationDate(); 
        database.executebatch(b);
    }
}