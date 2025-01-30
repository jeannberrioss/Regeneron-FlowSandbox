@IsTest
private class LatestChatterPostHandlerTest {
    @TestSetup
    static void setup() {
        Contact testContact = new Contact(LastName = 'Test');
        insert testContact;
    }

    // TEST 1: Insert a TextPost and verify the Contact's field updates
    @IsTest
    static void testInsertTextPost() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        FeedItem post = new FeedItem(
            ParentId = con.Id,
            Type = 'TextPost',
            Body = 'Test Post'
        );
        insert post;
        Test.stopTest();
        
        Contact updatedCon = [SELECT Latest_Chatter_Post__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Test Post', updatedCon.Latest_Chatter_Post__c, 'Contact field should match latest post');
    }

    // TEST 2: Update a TextPost and verify the Contact's field updates
    @IsTest
    static void testUpdateTextPost() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        FeedItem post = new FeedItem(ParentId = con.Id, Type = 'TextPost', Body = 'Original');
        insert post;
        
        Test.startTest();
        post.Body = 'Updated';
        update post;
        Test.stopTest();
        
        Contact updatedCon = [SELECT Latest_Chatter_Post__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Updated', updatedCon.Latest_Chatter_Post__c, 'Contact field should reflect updated post');
    }

    // TEST 3: Delete the latest TextPost and verify the Contact's field rolls back
    @IsTest
    static void testDeleteLatestPost() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        FeedItem post1 = new FeedItem(ParentId = con.Id, Type = 'TextPost', Body = 'First');
        FeedItem post2 = new FeedItem(ParentId = con.Id, Type = 'TextPost', Body = 'Second');
        insert post1;
        Test.setCreatedDate(post1.Id, DateTime.now().addDays(-1)); // Force post1 to be older
        insert post2;
        
        Test.startTest();
        delete post2;
        Test.stopTest();
        
        Contact updatedCon = [SELECT Latest_Chatter_Post__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('First', updatedCon.Latest_Chatter_Post__c, 'Contact field should roll back to older post');
    }

    // TEST 4: Delete all TextPosts and verify the Contact's field clears
    @IsTest
    static void testDeleteAllPosts() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        FeedItem post = new FeedItem(ParentId = con.Id, Type = 'TextPost', Body = 'Test');
        insert post;
        
        Test.startTest();
        delete post;
        Test.stopTest();
        
        Contact updatedCon = [SELECT Latest_Chatter_Post__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(null, updatedCon.Latest_Chatter_Post__c, 'Field clears when no posts exist');
    }

    // TEST 5: Ignore non-TextPost FeedItems (e.g., LinkPost)
    @IsTest
    static void testNonTextPostIgnored() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        FeedItem post = new FeedItem(
            ParentId = con.Id,
            Type = 'LinkPost',
            Body = 'Test Link',
            LinkUrl = 'https://example.com' // Required for LinkPost
        );
        insert post;
        Test.stopTest();
        
        Contact updatedCon = [SELECT Latest_Chatter_Post__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(null, updatedCon.Latest_Chatter_Post__c, 'Non-TextPost ignored');
    }

    // TEST 6: Bulk insert 200 posts (governor limit test)
    @IsTest
    static void testBulkInsert() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<FeedItem> posts = new List<FeedItem>();
        
        // Create 200 posts with Body "Post 0" to "Post 199"
        for (Integer i = 0; i < 200; i++) {
            posts.add(new FeedItem(
                ParentId = con.Id,
                Type = 'TextPost',
                Body = 'Post ' + i
            ));
        }
        
        insert posts; // Insert all posts (default CreatedDate = same for all)
        
        // Query inserted posts (order may be arbitrary due to same CreatedDate)
        List<FeedItem> insertedPosts = [SELECT Id FROM FeedItem ORDER BY CreatedDate ASC];
        
        // Set unique CreatedDates for each post (199 minutes apart)
        DateTime fixedDateTime = DateTime.newInstance(2023, 10, 1, 0, 0, 0);
        for (Integer i = 0; i < insertedPosts.size(); i++) {
            Test.setCreatedDate(insertedPosts[i].Id, fixedDateTime.addMinutes(-(199 - i)));
        }
        
        Test.startTest();
        // Re-trigger the handler logic to recognize the new CreatedDates
        update insertedPosts; 
        Test.stopTest();
        
        // Verify "Post 199" is the latest
        Contact updatedCon = [SELECT Latest_Chatter_Post__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Post 199', updatedCon.Latest_Chatter_Post__c, 'Bulk handling works');
    }
}