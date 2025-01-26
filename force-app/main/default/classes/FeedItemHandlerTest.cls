@isTest
private class FeedItemHandlerTest {
    @testSetup
    static void setup() {
        // Create test data
        RGC_Data_Assets__c asset = new RGC_Data_Assets__c(Name = 'Test Asset');
        insert asset;
        
        RGC_Lead__c lead1 = new RGC_Lead__c(Name = 'Lead A');
        RGC_Lead__c lead2 = new RGC_Lead__c(Name = 'Lead B');
        insert new List<RGC_Lead__c>{lead1, lead2};
    }

    // Test 1: TextPost updates Latest_Chatter_Post__c
    @isTest
    static void testTextPostUpdatesField() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        Test.startTest();
        insert new FeedItem(
            ParentId = asset.Id,
            Type = 'TextPost',
            Body = 'Test Chatter Post'
        );
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals('Test Chatter Post', result.Latest_Chatter_Post__c,
                          'Should populate from TextPost body');
    }

    // Test 2: LinkPost updates field with URL
    @isTest
    static void testLinkPostUpdatesField() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        Test.startTest();
        insert new FeedItem(
            ParentId = asset.Id,
            Type = 'LinkPost',
            Body = 'https://example.com'
        );
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals('https://example.com', result.Latest_Chatter_Post__c);
    }

    // Test 3: Long text truncation
    @isTest
    static void testLongTextTruncation() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        String longText = 'a'.repeat(300);
        
        Test.startTest();
        insert new FeedItem(
            ParentId = asset.Id,
            Type = 'TextPost',
            Body = longText
        );
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals(255, result.Latest_Chatter_Post__c.length(),
                          'Should truncate to 255 characters');
    }

    // Test 4: TrackedChange with no valid changes
    @isTest
    static void testTrackedChangeWithNoValidChanges() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        Test.startTest();
        insert new FeedItem(
            ParentId = asset.Id,
            Type = 'TrackedChange'
        );
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals(null, result.Latest_Chatter_Post__c,
                          'Should not update for invalid TrackedChange');
    }

    // Test 5: Bulk processing of multiple feed items
    @isTest
    static void testBulkProcessing() {
        List<RGC_Data_Assets__c> assets = new List<RGC_Data_Assets__c>();
        for(Integer i=0; i<10; i++) {
            assets.add(new RGC_Data_Assets__c(Name = 'Asset '+i));
        }
        insert assets;
        
        List<FeedItem> posts = new List<FeedItem>();
        for(RGC_Data_Assets__c asset : assets) {
            posts.add(new FeedItem(
                ParentId = asset.Id,
                Type = 'TextPost',
                Body = 'Post for '+asset.Name
            ));
        }
        
        Test.startTest();
        insert posts;
        Test.stopTest();
        
        List<RGC_Data_Assets__c> results = [SELECT Latest_Chatter_Post__c 
                                          FROM RGC_Data_Assets__c 
                                          WHERE Id IN :assets];
        System.assertEquals(10, results.size());
        for(RGC_Data_Assets__c a : results) {
            System.assert(a.Latest_Chatter_Post__c.startsWith('Post for'));
        }
    }

    // Test 6: Mixed feed item types
    @isTest
    static void testMixedFeedItemTypes() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        List<FeedItem> posts = new List<FeedItem>{
            new FeedItem( // Should be last processed
                ParentId = asset.Id,
                Type = 'TextPost',
                Body = 'Final Post',
                CreatedDate = System.now()
            ),
            new FeedItem(
                ParentId = asset.Id,
                Type = 'LinkPost',
                Body = 'https://old.com',
                CreatedDate = System.now().addMinutes(-5)
            )
        };
        
        Test.startTest();
        insert posts;
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals('Final Post', result.Latest_Chatter_Post__c,
                          'Should take latest feed item');
    }
}