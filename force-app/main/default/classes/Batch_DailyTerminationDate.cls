public class Batch_DailyTerminationDate implements Database.Batchable<SObject>,Database.Stateful {
	public string query;
    public static final Email_Recipient_User_List__mdt metadata = [SELECT Id, Agreement_Terminated_Yesterday__c, Agreement_Terminating_in_90_Days__c, 
                                                                   Agreement_Terminating_in_180_Days__c, Agreement_Terminating_in_180_Days_wo_Bud__c 
                                                                   FROM Email_Recipient_User_List__mdt where MasterLabel = 'User List' LIMIT 1];
    
    public Database.Querylocator start(Database.BatchableContext BC){
        query = 'SELECT Id, Name, Active_End_Date__c, Termination_Email_Sent__c, CV_signoff_Budget__c, Termination_Date_Processed__c, Collaboration_Status_1__c FROM Opportunity WHERE Termination_Date_Processed__c = TRUE';
        system.debug('query :: '+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        System.debug('scope: ' + scope.size());
        List<Opportunity> oppt = new List<Opportunity>();
        List<Opportunity> opptYesterday = new List<Opportunity>();
        List<Opportunity> oppt90Days = new List<Opportunity>();
        List<Opportunity> oppt180DaysWOBudget = new List<Opportunity>();
        List<Opportunity> oppt180DaysWBudget = new List<Opportunity>();
        
        for(Opportunity obj : scope) {
            if(obj.Active_End_Date__c < Date.Today()){ obj.Collaboration_Status_1__c = 'End of Term'; obj.Termination_Email_Sent__c = true; oppt.add(obj); }
            if(obj.Active_End_Date__c == (Date.Today() - 1)){ opptYesterday.add(obj); }// obj.Termination_Email_Sent__c = true; otherOppt.add(obj); }
            else if(obj.Active_End_Date__c == (Date.Today() + 90)){ oppt90Days.add(obj); } //obj.Termination_Email_Sent__c = true; otherOppt.add(obj); }
            else if(obj.Active_End_Date__c == (Date.Today() + 180) && obj.CV_signoff_Budget__c > 0){ oppt180DaysWBudget.add(obj); } //obj.Termination_Email_Sent__c = true; otherOppt.add(obj); }
            else if(obj.Active_End_Date__c == (Date.Today() + 180)){ oppt180DaysWOBudget.add(obj); } //obj.Termination_Email_Sent__c = true; otherOppt.add(obj); }
            System.debug('obj: ' + obj);
        }
        System.debug('oppt: ' + oppt.size());
        System.debug('opptYesterday: ' + opptYesterday.size());
        System.debug('oppt90Days: ' + oppt90Days.size());
        System.debug('oppt180DaysWOBudget: ' + oppt180DaysWOBudget.size());
        System.debug('oppt180DaysWBudget: ' + oppt180DaysWBudget.size());
        if(oppt.size() > 0){ 
            Database.update(oppt, false);
        }
        if(opptYesterday.size() > 0){ sendEmail(opptYesterday, 'Agreement_Terminated_Yesterday'); }
        if(oppt90Days.size() > 0){ sendEmail(oppt90Days, 'Agreement_Terminating_in_90_Days'); }
        if(oppt180DaysWOBudget.size() > 0){ sendEmail(oppt180DaysWOBudget, 'Agreement_Terminating_in_180_Days'); }
        if(oppt180DaysWBudget.size() > 0){ sendEmail(oppt180DaysWBudget, 'Agreement_Terminating_in_180_Days_wo_Budget'); }
    }
    
    public void sendEmail(List<Opportunity> scope, String templateName){
        System.debug('templateName: ' + templateName);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = [ Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where DeveloperName =: templateName ];
        Messaging.SingleEmailMessage mail;
        System.debug('emailTemplate: ' + emailTemplate);
        // Create Contact
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'no-reply@organization.com');
        Database.insert(con);
        
        for(Opportunity obj : scope) {
            mail = new Messaging.SingleEmailMessage();
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setTargetObjectId(con.Id);
            mail.setUseSignature(false); 
            mail.setBccSender(false); 
            mail.setSaveAsActivity(false);
            mail.setTemplateID(emailTemplate.Id);
            mail.setWhatId(obj.Id);
            List<String> userList = userList(templateName);
            if(userList.size() > 0){
                mail.setToAddresses(userList);
            	mails.add(mail);
            }
        }
        if(mails.size() > 0){
            System.debug('sending');
        	Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
        }
        Database.delete(con);
    }
    
    public List<String> userList(String Template){
        List<String> emailList = new List<String>();
        String emailListString = '';
        if(Template == 'Agreement_Terminated_Yesterday'){ emailListString = metadata.Agreement_Terminated_Yesterday__c; }
        else if(Template == 'Agreement_Terminating_in_90_Days'){ emailListString = metadata.Agreement_Terminating_in_90_Days__c; }
        else if(Template == 'Agreement_Terminating_in_180_Days'){ emailListString = metadata.Agreement_Terminating_in_180_Days__c; }
        else if(Template == 'Agreement_Terminating_in_180_Days_wo_Budget'){ emailListString = metadata.Agreement_Terminating_in_180_Days_wo_Bud__c; }
        System.debug('metadata: ' + metadata);
        System.debug('email list: ' + emailListString);
        if(emailListString != ''){ emailList = emailListString.split(','); return emailList; }
        else{ return new List<String>(); }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}