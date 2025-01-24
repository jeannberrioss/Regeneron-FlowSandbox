@IsTest
public class FeedItemTriggerTest {
    // Test setup method to create common test data
    @TestSetup
    static void setupTestData() {
        // Create 2 RGC Data Assets
        List<RGC_Data_Assets__c> testAssets = new List<RGC_Data_Assets__c>{
            new RGC_Data_Assets__c(Name = 'Test Asset 1'),
            new RGC_Data_Assets__c(Name = 'Test Asset 2')
        };
        insert testAssets;

        // Create FeedItems for Asset 1 with different timestamps
        List<FeedItem> asset1Posts = new List<FeedItem>{
            // Oldest post (will be first in list but last in CreatedDate)
            new FeedItem(
                ParentId = testAssets[0].Id,
                Body = 'Asset 1 - First Post',
                Type = 'TextPost'
            ),
            // Newest post (will be last in list but first in CreatedDate)
            new FeedItem(
                ParentId = testAssets[0].Id,
                Body = 'Asset 1 - Latest Post',
                Type = 'TextPost'
            )
        };
        insert asset1Posts;

        // Force CreatedDate for time-sensitive testing
        Test.setCreatedDate(asset1Posts[0].Id, DateTime.now().addHours(-2));
        Test.setCreatedDate(asset1Posts[1].Id, DateTime.now().addHours(-1));
    }

    // Test 1: Verify new FeedItem updates Latest_Chatter_Post__c
    @IsTest
    static void testInsertFeedItem() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c WHERE Name = 'Test Asset 2'];
        
        Test.startTest();
        // Insert new post for Asset 2
        insert new FeedItem(
            ParentId = asset.Id,
            Body = 'New Test Post',
            Type = 'TextPost'
        );
        Test.stopTest();

        // Verify update
        RGC_Data_Assets__c updatedAsset = [SELECT Latest_Chatter_Post__c 
                                         FROM RGC_Data_Assets__c 
                                         WHERE Id = :asset.Id];
        System.assertEquals('New Test Post', updatedAsset.Latest_Chatter_Post__c,
                           'Latest post not updated on insert');
    }

    // Test 2: Verify FeedItem update triggers field update
    @IsTest
    static void testUpdateFeedItem() {
        FeedItem post = [SELECT Id, Body FROM FeedItem WHERE Body = 'Asset 1 - Latest Post'];
        
        Test.startTest();
        post.Body = 'Updated Latest Post';
        update post;
        Test.stopTest();

        // Verify update
        RGC_Data_Assets__c asset = [SELECT Latest_Chatter_Post__c 
                                  FROM RGC_Data_Assets__c 
                                  WHERE Name = 'Test Asset 1'];
        System.assertEquals('Updated Latest Post', asset.Latest_Chatter_Post__c,
                           'Latest post not updated on modification');
    }

    // Test 3: Verify deleting latest post shows previous post
    @IsTest
    static void testDeleteLatestFeedItem() {
        FeedItem latestPost = [SELECT Id FROM FeedItem WHERE Body = 'Asset 1 - Latest Post'];
        
        Test.startTest();
        delete latestPost;
        Test.stopTest();

        // Verify rollback to previous post
        RGC_Data_Assets__c asset = [SELECT Latest_Chatter_Post__c 
                                  FROM RGC_Data_Assets__c 
                                  WHERE Name = 'Test Asset 1'];
        System.assertEquals('Asset 1 - First Post', asset.Latest_Chatter_Post__c,
                           'Did not revert to previous post after deletion');
    }

    // Test 4: Verify deleting all posts clears the field
    @IsTest
    static void testDeleteAllFeedItems() {
        List<FeedItem> posts = [SELECT Id FROM FeedItem 
                              WHERE ParentId IN (SELECT Id FROM RGC_Data_Assets__c 
                                               WHERE Name = 'Test Asset 1')];
        
        Test.startTest();
        delete posts;
        Test.stopTest();

        // Verify field clearance
        RGC_Data_Assets__c asset = [SELECT Latest_Chatter_Post__c 
                                  FROM RGC_Data_Assets__c 
                                  WHERE Name = 'Test Asset 1'];
        System.assertNull(asset.Latest_Chatter_Post__c,
                         'Field not cleared after deleting all posts');
    }

    // Test 5: Verify non-RGC parents are ignored
    @IsTest
    static void testNonRgcParent() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Test.startTest();
        FeedItem nonRgcPost = new FeedItem(
            ParentId = testAccount.Id,
            Body = 'Non-RGC Post',
            Type = 'TextPost'
        );
        insert nonRgcPost;
        Test.stopTest();

        // Verify no RGC records were updated
        List<RGC_Data_Assets__c> assets = [SELECT Latest_Chatter_Post__c 
                                         FROM RGC_Data_Assets__c];
        for(RGC_Data_Assets__c asset : assets) {
            System.assertNotEquals('Non-RGC Post', asset.Latest_Chatter_Post__c,
                                  'Incorrectly updated non-RGC parent');
        }
    }

    // Test 6: Verify bulk processing (200+ records)
    @IsTest
    static void testBulkOperations() {
        List<RGC_Data_Assets__c> bulkAssets = new List<RGC_Data_Assets__c>();
        List<FeedItem> bulkPosts = new List<FeedItem>();
        
        // Create 200 test assets
        for(Integer i=0; i<200; i++) {
            bulkAssets.add(new RGC_Data_Assets__c(Name = 'Bulk Asset ' + i));
        }
        insert bulkAssets;

        // Create 2 posts per asset
        for(RGC_Data_Assets__c asset : bulkAssets) {
            bulkPosts.add(new FeedItem(
                ParentId = asset.Id,
                Body = 'First Post',
                Type = 'TextPost'
            ));
            bulkPosts.add(new FeedItem(
                ParentId = asset.Id,
                Body = 'Latest Post',
                Type = 'TextPost'
            ));
        }
        
        Test.startTest();
        insert bulkPosts;
        Test.stopTest();

        // Verify all assets have latest post
        List<RGC_Data_Assets__c> updatedAssets = [SELECT Latest_Chatter_Post__c 
                                                FROM RGC_Data_Assets__c 
                                                WHERE Name LIKE 'Bulk Asset %'];
        System.assertEquals(200, updatedAssets.size(),
                          'Incorrect number of assets processed');
        for(RGC_Data_Assets__c asset : updatedAssets) {
            System.assertEquals('Latest Post', asset.Latest_Chatter_Post__c,
                               'Bulk post not updated correctly');
        }
    }
}