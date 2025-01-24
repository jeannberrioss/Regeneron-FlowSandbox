@isTest
private class RGCDataAssetFeedTriggerTest {
    @testSetup
    static void setup() {
        // Create test data
        RGC_Lead__c lead1 = new RGC_Lead__c(Name = 'Lead A');
        RGC_Lead__c lead2 = new RGC_Lead__c(Name = 'Lead B');
        insert new List<RGC_Lead__c>{lead1, lead2};
        
        RGC_Data_Assets__c asset = new RGC_Data_Assets__c(Name = 'Test Asset');
        insert asset;
    }
    
    @isTest
    static void testTrackedChange() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        RGC_Lead__c lead1 = [SELECT Id FROM RGC_Lead__c WHERE Name = 'Lead A' LIMIT 1];
        RGC_Lead__c lead2 = [SELECT Id FROM RGC_Lead__c WHERE Name = 'Lead B' LIMIT 1];
        
        // Simulate a TrackedChange
        FeedItem trackedChange = new FeedItem(
            ParentId = asset.Id,
            Type = 'TrackedChange',
            Body = 'Changed Clinical Lead'
        );
        insert trackedChange;
        
        // Add FeedTrackedChange for Clinical_Informatics_Lead__c
        FeedTrackedChange ftc = new FeedTrackedChange(
            FeedItemId = trackedChange.Id,
            FieldName = 'Clinical_Informatics_Lead__c',
            OldValue = lead1.Id,
            NewValue = lead2.Id
        );
        insert ftc;
        
        Test.startTest();
        // Trigger is already executed due to insert
        Test.stopTest();
        
        // Verify
        RGC_Data_Assets__c updatedAsset = [SELECT Latest_Chatter_Post__c FROM RGC_Data_Assets__c LIMIT 1];
        System.assert(updatedAsset.Latest_Chatter_Post__c.contains('Lead A to Lead B'));
    }
    
    @isTest
    static void testTextPost() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        
        // Create a TextPost
        FeedItem textPost = new FeedItem(
            ParentId = asset.Id,
            Type = 'TextPost',
            Body = 'Test Chatter Post'
        );
        insert textPost;
        
        Test.startTest();
        // Trigger is already executed due to insert
        Test.stopTest();
        
        // Verify
        RGC_Data_Assets__c updatedAsset = [SELECT Latest_Chatter_Post__c FROM RGC_Data_Assets__c LIMIT 1];
        System.assertEquals('Test Chatter Post', updatedAsset.Latest_Chatter_Post__c);
    }
}