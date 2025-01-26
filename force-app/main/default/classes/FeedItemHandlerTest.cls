@isTest
private class FeedItemHandlerTest {
    @testSetup
    static void setup() {
        // Create collaboration record (auto-number name)
        RGC_Collaboration__c collaboration = new RGC_Collaboration__c();
        insert collaboration;

        // Create asset with lookup to collaboration
        RGC_Data_Assets__c asset = new RGC_Data_Assets__c(
            RGC_Collaboration_Detail__c = collaboration.Id
        );
        insert asset;

        // Create test leads
        RGC_Lead__c lead1 = new RGC_Lead__c(Name = 'Lead A');
        RGC_Lead__c lead2 = new RGC_Lead__c(Name = 'Lead B');
        insert new List<RGC_Lead__c>{lead1, lead2};
    }

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
        System.assertEquals('Test Chatter Post', result.Latest_Chatter_Post__c);
    }

    @isTest
    static void testLinkPostUpdatesField() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        Test.startTest();
        insert new FeedItem(
            ParentId = asset.Id,
            Type = 'LinkPost',
            Body = 'https://salesforce.com'
        );
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals('https://salesforce.com', result.Latest_Chatter_Post__c);
    }

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
        System.assertEquals(255, result.Latest_Chatter_Post__c?.length());
    }

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
        System.assertEquals(null, result.Latest_Chatter_Post__c);
    }

    @isTest
    static void testBulkProcessing() {
        // Create bulk collaboration record
        RGC_Collaboration__c bulkCollaboration = new RGC_Collaboration__c();
        insert bulkCollaboration;

        List<RGC_Data_Assets__c> assets = new List<RGC_Data_Assets__c>();
        for(Integer i=0; i<10; i++) {
            assets.add(new RGC_Data_Assets__c(
                RGC_Collaboration_Detail__c = bulkCollaboration.Id
            ));
        }
        insert assets;
        
        List<FeedItem> posts = new List<FeedItem>();
        for(RGC_Data_Assets__c asset : assets) {
            posts.add(new FeedItem(
                ParentId = asset.Id,
                Type = 'TextPost',
                Body = 'Post for '+asset.Id
            ));
        }
        
        Test.startTest();
        insert posts;
        Test.stopTest();
        
        List<RGC_Data_Assets__c> results = [SELECT Latest_Chatter_Post__c 
                                          FROM RGC_Data_Assets__c 
                                          WHERE Id IN :assets];
        System.assertEquals(10, results.size());
    }

    @isTest
    static void testMixedFeedItemTypes() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        List<FeedItem> posts = new List<FeedItem>{
            new FeedItem(
                ParentId = asset.Id,
                Type = 'LinkPost',
                Body = 'https://old.com',
                CreatedDate = System.now().addHours(-2)
            ),
            new FeedItem(
                ParentId = asset.Id,
                Type = 'TextPost',
                Body = 'Most Recent Update',
                CreatedDate = System.now().addHours(-1)
            )
        };
        
        Test.startTest();
        insert posts;
        Test.stopTest();
        
        RGC_Data_Assets__c result = [SELECT Latest_Chatter_Post__c 
                                   FROM RGC_Data_Assets__c 
                                   WHERE Id = :asset.Id];
        System.assertEquals('Most Recent Update', result.Latest_Chatter_Post__c);
    }
}