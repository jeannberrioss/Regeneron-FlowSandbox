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
        @isTest
    static void testDeleteTextPostInitiallyNull() {
        // 1. Setup Test Data
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        // Create RGC_Data_Assets__c with Latest_Chatter_Post__c initially NULL (default)
        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert dataAsset;
        
        FeedItem textPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'TextPost',
            Body = 'A text post to be deleted.'
        );
        insert textPost;

        // 2. Perform Test Action - Delete the TextPost (Trigger Fires)
        Test.startTest();
        delete textPost;
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        Assert.isNull(updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should remain NULL when deleting a TextPost and it was initially NULL.');
    }
        @isTest
    static void testBulkInsertUpdateDelete() {
        // 1. Setup Test Data - Create multiple Collaborations and Data Assets
        List<RGC_Collaboration__c> collaborations = new List<RGC_Collaboration__c>();
        for (Integer i = 0; i < 3; i++) {
            collaborations.add(new RGC_Collaboration__c());
        }
        insert collaborations;

        List<RGC_Data_Assets__c> dataAssets = new List<RGC_Data_Assets__c>();
        for (Integer i = 0; i < 3; i++) {
            dataAssets.add(new RGC_Data_Assets__c(
                Name = 'Test Data Asset ' + i,
                RGC_Collaboration_Detail__c = collaborations[i].Id
            ));
        }
        insert dataAssets;

        // Create FeedItems for bulk insert, update, and delete
        List<FeedItem> feedItemsToInsert = new List<FeedItem>();
        List<FeedItem> feedItemsToUpdate = new List<FeedItem>();
        List<FeedItem> feedItemsToDelete = new List<FeedItem>();

        // Data Asset 0: Insert 2 posts, update 1, delete 1 (leaving the older one)
        feedItemsToInsert.add(new FeedItem(ParentId = dataAssets[0].Id, Type = 'TextPost', Body = 'Initial Post 1 for Asset 0', CreatedDate = System.now().addHours(-2)));
        FeedItem latestPostAsset0 = new FeedItem(ParentId = dataAssets[0].Id, Type = 'TextPost', Body = 'Initial Post 2 for Asset 0', CreatedDate = System.now().addHours(-1));
        feedItemsToInsert.add(latestPostAsset0);
        feedItemsToUpdate.add(latestPostAsset0); // Will update this one
        feedItemsToDelete.add(latestPostAsset0); // Will delete this one

        // Data Asset 1: Insert 1 post, delete it (should set Latest_Chatter_Post__c to null)
        FeedItem onlyPostAsset1 = new FeedItem(ParentId = dataAssets[1].Id, Type = 'TextPost', Body = 'Only Post for Asset 1');
        feedItemsToInsert.add(onlyPostAsset1);
        feedItemsToDelete.add(onlyPostAsset1);

        // Data Asset 2: Insert 1 post, no updates or deletes (should remain as latest post)
        feedItemsToInsert.add(new FeedItem(ParentId = dataAssets[2].Id, Type = 'TextPost', Body = 'Only Post for Asset 2'));


        insert feedItemsToInsert; // Bulk Insert

        // Update one of the inserted FeedItems
        feedItemsToUpdate[0].Body = 'Updated Post for Asset 0';
        update feedItemsToUpdate; // Bulk Update

        // 2. Perform Test Actions - Bulk Delete FeedItems (Trigger Fires multiple times)
        Test.startTest();
        delete feedItemsToDelete; // Bulk Delete
        Test.stopTest();

        // 3. Assertions - Verify Latest_Chatter_Post__c on Data Assets
        List<RGC_Data_Assets__c> updatedDataAssets = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id IN :dataAssets];

        // Asset 0: Should have the older post as the latest now
        System.assertEquals('Initial Post 1 for Asset 0', updatedDataAssets[0].Latest_Chatter_Post__c, 'Asset 0 - Latest_Chatter_Post__c should be the older post after delete.');

        // Asset 1: Should be NULL as the only post was deleted
        Assert.isNUll(updatedDataAssets[1].Latest_Chatter_Post__c, 'Asset 1 - Latest_Chatter_Post__c should be NULL after deleting the only post.');

        // Asset 2: Should still have its initial post
        System.assertEquals('Only Post for Asset 2', updatedDataAssets[2].Latest_Chatter_Post__c, 'Asset 2 - Latest_Chatter_Post__c should remain unchanged.');
    }
        @isTest
    static void testNonTextPostFeedItem() {
        // 1. Setup Test Data
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            Latest_Chatter_Post__c = 'Initial Chatter Post', // Set an initial value
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert dataAsset;

        // Create a FeedItem of type 'ContentPost' (or any type other than 'TextPost')
        FeedItem contentPost = new FeedItem(
            ParentId = dataAsset.Id,
            Type = 'ContentPost', // Using ContentPost as an example of a non-TextPost
            LinkUrl = 'http://www.example.com', // ContentPost requires LinkUrl
            Title = 'Test Content Post'
        );

        // 2. Perform Test Action - Insert the non-TextPost FeedItem (Trigger Fires)
        Test.startTest();
        insert contentPost;
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        System.assertEquals('Initial Chatter Post', updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should NOT be changed when a non-TextPost FeedItem is inserted.');
    }
        @isTest
    static void testFeedItemOnDifferentObject() {
        // 1. Setup Test Data
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        RGC_Data_Assets__c dataAsset = new RGC_Data_Assets__c(
            Name = 'Test Data Asset',
            Latest_Chatter_Post__c = 'Initial Chatter Post', // Set an initial value
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert dataAsset;

        // Create an Account record (different parent object)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a TextPost FeedItem associated with the Account (NOT RGC_Data_Assets__c)
        FeedItem accountTextPost = new FeedItem(
            ParentId = testAccount.Id, // ParentId is the Account ID
            Type = 'TextPost',
            Body = 'Text Post on Account'
        );

        // 2. Perform Test Action - Insert FeedItem on Account (Trigger Fires)
        Test.startTest();
        insert accountTextPost;
        Test.stopTest();

        // 3. Assertion
        RGC_Data_Assets__c updatedDataAsset = [SELECT Id, Latest_Chatter_Post__c FROM RGC_Data_Assets__c WHERE Id = :dataAsset.Id];
        System.assertEquals('Initial Chatter Post', updatedDataAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should NOT be changed when a TextPost is on a different object (Account).');
    }
            @isTest
    static void testFeedItemNullParentId() {
        // 1. Setup Test Data (No RGC_Data_Assets__c needed for this test)

        // Create a TextPost FeedItem with ParentId = null
        FeedItem nullParentIdTextPost = new FeedItem(
            ParentId = null, // ParentId is explicitly set to null
            Type = 'TextPost',
            Body = 'Text Post with Null ParentId'
        );

        // 2. Perform Test Action - Attempt to Insert FeedItem with Null ParentId and EXPECT an exception
        Boolean exceptionCaught = false;
        try {
            Test.startTest();
            insert nullParentIdTextPost; // This should throw a DmlException
            Test.stopTest();
        } catch (DmlException e) {
            exceptionCaught = true;
            System.debug('DmlException caught as expected: ' + e.getMessage());
            // Optionally, you can add more specific assertions about the exception message if needed.
            // Assert.isTrue(e.getMessage().contains('REQUIRED_FIELD_MISSING'), 'Exception message should indicate REQUIRED_FIELD_MISSING.');
        }

        // 3. Assertion - Verify that a DmlException was caught
        Assert.isTrue(exceptionCaught, 'DmlException should have been thrown when inserting FeedItem with null ParentId.');

        // 4. Assertion - Verify no RGC_Data_Assets__c records were updated (still important)
        List<RGC_Data_Assets__c> updatedAssets = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        Assert.isTrue(updatedAssets.isEmpty(), 'No RGC_Data_Assets__c records should be updated when FeedItem insert fails.');
    }
}