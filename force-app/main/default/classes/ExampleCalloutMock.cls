@isTest
global class ExampleCalloutMock implements HttpCalloutMock{
    global HttpResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint() == 'https://logo.clearbit.com/https://www.google.com/'){
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('GOT IMAGE URL');
        }else{
            res.setStatus('ERROR!');
            res.setStatusCode(404);
            res.setBody('DIDNT IMAGE URL');
        }
        return res;
    }
}