@isTest
private class RGCDataAssetFeedTriggerTest {
    @testSetup
    static void setup() {
        // Create test data
        RGC_Lead__c lead1 = new RGC_Lead__c(Name = 'Lead A');
        RGC_Lead__c lead2 = new RGC_Lead__c(Name = 'Lead B');
        insert new List<RGC_Lead__c>{lead1, lead2};
        
        // Create RGC_Data_Assets__c record with required fields
        RGC_Data_Assets__c asset = new RGC_Data_Assets__c(
            Name = 'Test Asset',
            RGC_Collaboration_Detail__c = 'Test Collaboration Detail' // Include required field
        );
        insert asset;
    }
    
    @isTest
    static void testTrackedChange() {
        RGC_Data_Assets__c asset = [SELECT Id FROM RGC_Data_Assets__c LIMIT 1];
        RGC_Lead__c lead1 = [SELECT Id FROM RGC_Lead__c WHERE Name = 'Lead A' LIMIT 1];
        RGC_Lead__c lead2 = [SELECT Id FROM RGC_Lead__c WHERE Name = 'Lead B' LIMIT 1];
        
        // Simulate a TrackedChange by updating the lookup field
        asset.Clinical_Informatics_Lead__c = lead1.Id;
        update asset;
        
        // Simulate another TrackedChange by updating the lookup field again
        asset.Clinical_Informatics_Lead__c = lead2.Id;
        update asset;
        
        Test.startTest();
        // Query the FeedItem and FeedTrackedChange records created by the updates
        FeedItem trackedChange = [
            SELECT Id, ParentId, Type, CreatedDate, 
            (SELECT OldValue, NewValue FROM FeedTrackedChanges) 
            FROM FeedItem 
            WHERE ParentId = :asset.Id 
            AND Type = 'TrackedChange' 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        // Verify the FeedTrackedChange record
        System.assertEquals(1, trackedChange.FeedTrackedChanges.size(), 'Expected one FeedTrackedChange record');
        FeedTrackedChange ftc = trackedChange.FeedTrackedChanges[0];
        System.assertEquals(lead1.Id, ftc.OldValue, 'OldValue should match Lead A');
        System.assertEquals(lead2.Id, ftc.NewValue, 'NewValue should match Lead B');
        
        // Trigger logic will process this automatically
        Test.stopTest();
        
        // Verify the Latest_Chatter_Post__c field
        RGC_Data_Assets__c updatedAsset = [SELECT Latest_Chatter_Post__c FROM RGC_Data_Assets__c LIMIT 1];
        System.assert(updatedAsset.Latest_Chatter_Post__c.contains('Lead A to Lead B'), 'Latest_Chatter_Post__c should reflect the change');
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
        System.assertEquals('Test Chatter Post', updatedAsset.Latest_Chatter_Post__c, 'Latest_Chatter_Post__c should match the text post body');
    }
}