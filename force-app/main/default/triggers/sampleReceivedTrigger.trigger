trigger sampleReceivedTrigger on Sample_Received_Stage__c (before insert,before update,after insert,after update, after delete, after undelete) {

    Set<Id> opportunityIds = new Set<Id>();

    if(trigger.isInsert || trigger.isUpdate || trigger.isUndelete){
        for(Sample_Received_Stage__c sample:trigger.new){
            if(sample.Collaboration_Opportunity__c != null){
                opportunityIds.add(sample.Collaboration_Opportunity__c);
            }
        }
    }

    if(trigger.isUpdate || trigger.isDelete){
        for(Sample_Received_Stage__c sample:trigger.old){
            if(sample.Collaboration_Opportunity__c != null){
                opportunityIds.add(sample.Collaboration_Opportunity__c);
            }
        }
    }

    if(!opportunityIds.isEmpty()){
        List<AggregateResult> oppList = [Select Collaboration_Opportunity__c,sum(Quantity__c) totalcount from Sample_Received_Stage__c  WHERE Collaboration_Opportunity__c IN : opportunityIds group by Collaboration_Opportunity__c ];
        if(!oppList.isEmpty()){
            List<Opportunity> updateOpportunity = new List<Opportunity>();
            for(AggregateResult opp: oppList){
                Opportunity OpportunityObj = new Opportunity(Id = (Id)opp.get('Collaboration_Opportunity__c'), Total_Samples_Received__c = Integer.valueOf(opp.get('totalcount')));
                updateOpportunity.add(OpportunityObj);
            }
            if(!updateOpportunity.isEmpty()){
                System.debug(updateOpportunity);
                update updateOpportunity;
            }
        }
    }

}