trigger CollaborationOpportunityTrigger on Opportunity (before insert, before update, before delete, after update) {
    
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            for(Opportunity op : Trigger.New){
                if(op.Active_End_Date__c != null){
                    op.Termination_Date_Original__c = op.Active_End_Date__c;
                }
            }
        }
    }
    
    if (Trigger.isUpdate) {
        if (Trigger.isAfter && PreventRecursive.runOnce()) {
            System.debug('After Update');
            
            Map<Id, Opportunity> opptsId = new Map<Id, Opportunity>();
            for(Opportunity op : Trigger.New){
                opptsId.put(op.Id, op);
            }
            System.debug('opptsId: ' + opptsId);
            List<Opportunity> optListToUpdate = new List<Opportunity>();
            List<Opportunity> optList = [SELECT Id,Active_End_Date__c,Termination_Date_Original__c, 
                                         (SELECT Id, Termination_Date__c FROM Amendments__r Order By CreatedDate Desc) 
                                         FROM Opportunity WHERE Id IN :opptsId.keySet()];
            List<Opportunity> listToUpdate = new List<Opportunity>();
            for(Opportunity opt : optList){
                opptsId.get(opt.Id);
                List<Amendment__c> amdList = opt.Amendments__r;
                System.debug('amendment: ' + (amdList.size()));
                if(amdList.size() == 0){
                    opt.Termination_Date_Original__c = opptsId.get(opt.Id).Active_End_Date__c;
                    System.debug('opt: ' + opt.Termination_Date_Original__c);
                    optListToUpdate.add(opt);
                }
            }
            System.debug('optListToUpdate size: ' + (optListToUpdate.size()));
            if(optListToUpdate.size() > 0){
                update optListToUpdate;
            }
        }
    }
    // && PreventRecursive.runOnce()
    /*if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            System.debug('Before Update');
            Map<Id, Opportunity> opptsId = new Map<Id, Opportunity>();
            for(Opportunity op : Trigger.New){
                opptsId.put(op.Id, op);
            }
            System.debug('opptsId: ' + opptsId);
            
            List<Opportunity> optList = [SELECT Id,Active_End_Date__c,Termination_Date_Original__c, 
                                         (SELECT Id, Termination_Date__c FROM Amendments__r Order By CreatedDate Desc) 
                                         FROM Opportunity WHERE Id IN :opptsId.keySet()];
            List<Opportunity> listToUpdate = new List<Opportunity>();
            for(Opportunity opt : optList){
                opptsId.get(opt.Id);
                List<Amendment__c> amdList = opt.Amendments__r;
                System.debug('amendment: ' + (amdList.size()));
                if(amdList.size() == 0){
                    System.debug('opt.Active_End_Date__c: ' + opt.Active_End_Date__c);
                    //if(opt.Active_End_Date__c == null && opptsId.get(opt.Id).Termination_Date_Original__c != null){
                    //    opptsId.get(opt.Id).Termination_Date_Original__c = opptsId.get(opt.Id).Active_End_Date__c;
                    //}
                    //else{
                        opptsId.get(opt.Id).Active_End_Date__c = opt.Termination_Date_Original__c;
                    //}
                }
                else{
                    //opptsId.get(opt.Id).Termination_Date_Original__c = opptsId.get(opt.Id).Active_End_Date__c;
                    /*List<Amendment__c> listAmendment = new List<Amendment__c>();
                    Boolean dateFlag = true;
                    for(Amendment__c ad : opt.Amendments__r){
                        if(ad.Termination_Date__c != null && dateFlag){
                            opptsId.get(opt.Id).Active_End_Date__c = ad.Termination_Date__c;
                            listAmendment.add(ad);
                            dateFlag = false;
                        }
                    }
                }
            }
        }
    }*/
}