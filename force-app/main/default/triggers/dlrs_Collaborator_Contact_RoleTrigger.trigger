/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Collaborator_Contact_RoleTrigger on Collaborator_Contact_Role__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Collaborator_Contact_Role__c.SObjectType);
}