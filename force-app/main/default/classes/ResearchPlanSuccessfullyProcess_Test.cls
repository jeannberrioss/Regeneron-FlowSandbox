@isTest
public class ResearchPlanSuccessfullyProcess_Test {
        @testSetup static void testSetup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'RGC Power User'];
        User testRGCUser = new User ( Alias = 'RGCPU1', Email = 'testRGCPower@rgcpowerusertest.com',
                                EmailEncodingKey = 'UTF-8', LastName = 'poweruserRGC', LanguageLocaleKey = 'en_US',
                                LocaleSidKey = 'en_US', ProfileId = p.Id,
                                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testRGCPower@rgcpowerusertest.com');
        insert testRGCUser;
        User testRGCPowerUser = new User ( Alias = 'RGCPU2', Email = 'testRGCPowerUser@rgcpowerusertest.com',
                                EmailEncodingKey = 'UTF-8', LastName = 'powerRGCUser', LanguageLocaleKey = 'en_US',
                                LocaleSidKey = 'en_US', ProfileId = p.Id, PBO_Associate__c = true,
                                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testRGCPowerUser@rgcpowerusertest.com');
        insert testRGCPowerUser;                
        Account a = new Account ( Name = 'testInstitution',
                                  Country_global__c = 'United States of America',
                                  US_Non_US__c = 'Non-US');
        insert a;   
        }
    @isTest
    private static void ResearchPlanSuccessfullyProcess_MethodTest(){
        Account at = [SELECT Id, Country_global__c,US_Non_US__c  FROM Account WHERE Name = 'testInstitution' Limit 1];
        User userRGC = [SELECT Id,PBO_Associate__c  FROM User WHERE Username = 'testRGCPowerUser@rgcpowerusertest.com' Limit 1];
        Id opRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Single Institution Collaboration Opportunity').getRecordtypeID();
        Opportunity opt = new Opportunity(RecordTypeId = opRecordTypeID, name = 'Test Opty',
                                          StageName = 'Early Discussions', CloseDate = date.today() + 11,
                                          PBO_Associate__c = userRGC.id,
                                          Budget_Agreement__c = 'Completed',RPR_Final_Approval_Date__c = date.today(),
                                          RCA_Signatures__c = 'Completed',Funds_Available__c = date.today(),
                                          Budget_Itemization_Information_Available__c = date.today(),
                                          ICFs_Ready_for_Legal_Review__c = date.today(),
                                          Collaboration_Agreement_ready_for_Legal__c =  date.today(),
                                          Proceed_Based_on_Initial_Assessment__c = date.today(),
                                          Proceed_Based_on_Research_Plan__c  = date.today(),
                                          Term_Sheet_Agreed__c = date.today(),
                                          Informed_Consent_Forms_Approved__c  = date.today(),
                                          Research_Plan_Finalized__c = date.today(),
                                          All_RCA_Components_Completed__c = date.today(),
                                          Term_Sheet_agreed_by_RGC_LT__c = date.today(),
                                          ICFs_Available__c = date.today()
                                         );
        insert opt;
    }
}