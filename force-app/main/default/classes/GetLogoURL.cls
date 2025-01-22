public with sharing class GetLogoURL {
    public static ExampleCalloutMock mock = new ExampleCalloutMock();
    public static HttpRequest mockRequest = null;

    @future (callout=true)
    public static void fetchLogoUrl(Set<Id> accountIDs){
        Account[] records = [Select id, Website, Collab_Logo_Text__c from Account where id = :accountIDs];
        for(Account accRec : records){
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            String websiteURL= accRec.Website;
            System.debug('websiteURL---------->'+websiteURL);
            String endpointurl = 'http://logo.clearbit.com/'+websiteURL;
            System.debug('endpointurl------------->'+endpointurl);
                request.setEndpoint(endpointurl);
            request.setMethod('GET');
            if (Test.isRunningTest() && mockRequest!= null){
                response = mock.respond(mockRequest);
            }
            else if (!Test.isRunningTest()){
                response = new Http().send(request);  
            }
            System.debug(response.getStatusCode());
            if(response.getStatusCode() == 200){
                accRec.Collab_Logo_Text__c = endpointurl;
            }
            else if(response.getStatusCode() == 404){
                accRec.Collab_Logo_Text__c = 'http://logo.clearbit.com/www.regeneron.com/';
            }
        }
        
        update records;
    }
}