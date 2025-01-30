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
        @isTest
    static void testDeleteLastTextPost() {
        // 1. Setup Test Data
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert dataAsset;

        FeedItem textPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'TextPost',
            Body = 'This is the only text post.'
        );
        insert textPost;

        // 2. Perform Test Action - Delete the TextPost (Trigger Fires)
        Test.startTest();
        delete textPost;
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        Assert.isNULL(updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should be set to NULL after deleting the last TextPost.');
    }
        @isTest
    static void testUpdateExistingTextPost() {
        // 1. Setup Test Data
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert dataAsset;

        FeedItem textPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'TextPost',
            Body = 'Original text post body.'
        );
        insert textPost;

        // 2. Perform Test Action - Update the TextPost body (Trigger Fires)
        textPost.Body = 'Updated text post body.'; // Modify the body
        Test.startTest();
        update textPost; // Perform the update
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        Assert.areEqual('Updated text post body.', updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should be updated with the new TextPost body.');
    }
        @isTest
    static void testDeleteTextPostWithExistingPosts() {
        // 1. Setup Test Data
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert dataAsset;

        // Create two TextPosts, ensuring different CreatedDates for ordering
        FeedItem olderTextPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'TextPost',
            Body = 'Older text post.',
            CreatedDate = System.now().addHours(-1) // Set older CreatedDate
        );
        insert olderTextPost;

        FeedItem latestTextPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'TextPost',
            Body = 'Latest text post.',
            CreatedDate = System.now() // Latest CreatedDate
        );
        insert latestTextPost;

        // 2. Perform Test Action - Delete the LATEST TextPost (Trigger Fires)
        Test.startTest();
        delete latestTextPost; // Delete the latest one
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        Assert.areEqual('Older text post.', updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should be updated to the body of the older TextPost.');
    }
}