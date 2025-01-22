@isTest(SeeAllData = false)
public class GetLogoURLTest {
    @TestSetup
    private static void setup() {
        Account acc = new Account(Name='Test',Phone='768778687',Country_global__c='United States of America',US_Non_US__c='US', Website= 'https://www.google.com/');
        insert acc;
    }
    @isTest
    static void testAccountCreation() {
        Account accRec = [SELECT Id, Website FROM Account WHERE Name = 'Test'];
        Set<Id> accIDSet = new Set<Id>();
        accIDSet.add(accRec.Id);
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        HttpRequest request = new HttpRequest();
        String websiteURL= accRec.Website;
        System.debug('websiteURL---------->'+websiteURL);
        String endpointurl = 'https://logo.clearbit.com/'+websiteURL;
        request.setEndpoint(endpointurl);
        GetLogoURL.mockRequest = request;
        GetLogoURL.fetchLogoUrl(accIDSet);   
        Test.stopTest();
    }
    
    @isTest
    static void testAccountUpdate() {
        Account accRec = [SELECT Id, Website FROM Account WHERE Name = 'Test'];
        accRec.Website = 'https://www.tecsalud.mx/';
        update accRec;
        Set<Id> accIDSet = new Set<Id>();
        accIDSet.add(accRec.Id);
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        HttpRequest request = new HttpRequest();
        String websiteURL= accRec.Website;
        System.debug('websiteURL---------->'+websiteURL);
        String endpointurl = 'https://logo.clearbit.com/'+websiteURL;
        request.setEndpoint(endpointurl);
        GetLogoURL.mockRequest = request;
        GetLogoURL.fetchLogoUrl(accIDSet);    
        Test.stopTest();
    }
    
}