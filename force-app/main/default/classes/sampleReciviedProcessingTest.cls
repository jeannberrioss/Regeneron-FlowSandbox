@isTest
public with sharing class sampleReciviedProcessingTest {
    static testmethod void sampleReciviedProcessingRecord() {
        Account Ac = new Account(Name='Test',Phone='768778687',Country_global__c='United States of America',US_Non_US__c='US');
        Opportunity Op = new Opportunity(Name='Op1',AccountId=Ac.Id,StageName='7- Active',CloseDate=System.Today(),Collaborator_Key__c='DRIFT-NIMH',Budget__c='Budget',Agreement_Type__c='RCA - Research Collaboration Agreement',Geographic_Area__c='Domestic',Budget_Agreement__c='In Progress',Budget_Assessment__c='In Progress');
        insert Op;
        Opportunity Op2 = new Opportunity(Name='Op2',AccountId=Ac.Id,StageName='7- Active',CloseDate=System.Today(),Collaborator_Key__c='CNCD-EXPANSION',Budget__c='Budget',Agreement_Type__c='RCA - Research Collaboration Agreement',Geographic_Area__c='Domestic',Budget_Agreement__c='In Progress',Budget_Assessment__c='In Progress');
        insert Op2;
        String Msg = 'Collaborator,Project Name,Shipment,Num Samples\nDRIFT-NIMH,,9/23/2019,480\nCNCD-EXPANSION,,9/23/2019,22';
        sampleReciviedProcessing.paginationData Records = new sampleReciviedProcessing.paginationData();
        Records =  sampleReciviedProcessing.sampleReciviedProcessingRecord(Msg);
    }
    
    static testmethod void loadDataSampleTest(){
        Account Ac = new Account(Name='Test',Phone='768778687',Country_global__c='United States of America',US_Non_US__c='US');
        Opportunity Op = new Opportunity(Name='Op1',AccountId=Ac.Id,StageName='7- Active',CloseDate=System.Today(),Collaborator_Key__c='DRIFT-NIMH',Budget__c='Budget',Agreement_Type__c='RCA - Research Collaboration Agreement',Geographic_Area__c='Domestic',Budget_Agreement__c='In Progress',Budget_Assessment__c='In Progress');
        insert Op;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'TestData',
            PathOnClient = 'TestData.csv',
            VersionData = Blob.valueOf('Collaborator,Project Name,Shipment,Num Samples\nDRIFT-NIMH,,9/23/2019,480\nCNCD-EXPANSION,,9/23/2019,22'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        
        sampleReciviedProcessing.paginationData loadDataSample = new sampleReciviedProcessing.paginationData();
        loadDataSample = sampleReciviedProcessing.loadDataSample(documents[0].Id);
        
    }
    static testmethod void updateSampleTest(){
        Account Ac = new Account(Name='Test',Phone='768778687',Country_global__c='United States',US_Non_US__c='US');
        Opportunity Op = new Opportunity(Name='Op1',AccountId=Ac.Id,StageName='7- Active',CloseDate=System.Today(),Collaborator_Key__c='DRIFT-NIMH',Budget__c='Budget',Agreement_Type__c='RCA - Research Collaboration Agreement',Geographic_Area__c='Domestic',Budget_Agreement__c='In Progress',Budget_Assessment__c='In Progress');
        insert Op;
        
        Sample_Received_Stage__c St = new Sample_Received_Stage__c(Product__c='test',Quantity__c=5,Recivied_Date__c=System.Today(),Collaboration_Key__c='DRIFT-NIMH',Key__c='Test');
        insert St;
        
        Object Str = JSON.deserializeUntyped('[{"Quantity__c":"2499","Id":"'+Op.id+'"}]');
        string Str2 =  sampleReciviedProcessing.updateSample(Str) ;
    }
    @isTest
    public static void getLatestDataTest(){
        list<String> keySet = New list<String>();
        keySet.add('Test1');
        keySet.add('Test2');
        
        Test.startTest();
        sampleReciviedProcessing.getLatestData(keySet);
        Test.stopTest();
    }
    
}