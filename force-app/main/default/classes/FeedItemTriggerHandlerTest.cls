@isTest
private class FeedItemTriggerHandlerTest {

    @isTest
    static void testInsertNewTextPost() {
        // For this first test we have to temporarily de-activate the "RGC Data Asset Updates Data Assets" flow.
        // 1. Setup Test Data
        // Create a required RGC_Collaboration__c record
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c(); // Name is auto-number, do not set it
        insert collaboration;

        // Now create RGC_Data_Assets__c and link it using the CORRECT field API name: RGC_Collaboration_Detail__c
        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            RGC_Collaboration_Detail__c = collaboration.Id // Using RGC_Collaboration_Detail__c as the lookup field API name
        );
        insert dataAsset;

        FeedItem textPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'TextPost',
            Body = 'This is a test text post.'
        );

        // 2. Perform Test Action - Insert FeedItem (Trigger Fires)
        Test.startTest();
        insert textPost;
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        System.assertEquals('This is a test text post.', updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should be updated with the new TextPost body.');
    }
}