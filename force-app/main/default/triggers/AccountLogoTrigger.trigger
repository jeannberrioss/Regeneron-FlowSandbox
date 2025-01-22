trigger AccountLogoTrigger on Account (after insert, after update) {
    
    if(System.isFuture()) {
        return; // This is a recursive update, let's skip
    }
    Set<Id> updateAccount = new Set<Id>();
    if((Trigger.isInsert || Trigger.isUpdate)){
        for(Account accobj: Trigger.new){
            if(accObj.Website != null){
                updateAccount.add(accobj.Id); 
            }
        }
    }
    
    /*if(Trigger.isUpdate){
        for(Account accObjUpd : Trigger.new){
            Account oldAcc = Trigger.oldMap.get(accObjUpd.Id);
            if(Trigger.isUpdate && accObjUpd.Website != null && (accObjUpd.Website == null || accObjUpd.Website != oldAcc.Website)) {
                updateAccount.add(accObjUpd.Id);
            }
        }
    }*/
    if(updateAccount.size() > 0) {
        GetLogoURL.fetchLogoUrl(updateAccount);
    }
}