/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Collaborator_Contact_RoleTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Collaborator_Contact_RoleTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Collaborator_Contact_Role__c());
    }
}