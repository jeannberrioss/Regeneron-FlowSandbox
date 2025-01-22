@isTest
public class Test_DailyTerminationDate {
	@isTest
    static void TestMethod1() {
        List<Opportunity> allOppts = new List<Opportunity>();
        createOppt('Test Oppt 1', '0122E000000dFe8QAE', Date.today() - 1, 'Early Discussions', Date.today() + 5);
        createOppt('Test Oppt 2', '0122E000000dFe8QAE', Date.today() + 90, 'Early Discussions', Date.today() + 5);
        createOppt('Test Oppt 3', '0122E000000dFe8QAE', Date.today() + 180, 'Early Discussions', Date.today() + 5);
        
        Test.startTest();     
        String cronExpr = '0 0 0 15 3 ? 2022';
        String jobId = System.schedule('myJobTestJobName', cronExpr, new scheduledBatchable());
        //Batch_DailyTerminationDate InBatchObj = new Batch_DailyTerminationDate();
        //DataBase.executeBatch(InBatchObj,200);        
        Test.stopTest();
    }
    
    public static void createOppt(String Name, Id RecordTypeId, Date ActiveEndDate, String StageName, Date CloseDate){
        Opportunity oppt = new Opportunity(Name = Name, 
                                           RecordTypeId = RecordTypeId,
                                           Active_End_Date__c = ActiveEndDate,
                                           StageName = StageName,
                                           CloseDate = CloseDate);
        insert oppt;
    }
}