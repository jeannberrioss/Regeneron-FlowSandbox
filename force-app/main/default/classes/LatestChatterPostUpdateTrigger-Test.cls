@isTest
public class UpdateLatestChatterPostTest {
    @isTest
    static void testUpdateLatestChatterPost() {
        // Step 1: Create test RGC Data Asset records
        RGC_Data_Assets__c asset1 = new RGC_Data_Assets__c(Name = 'Asset 1');
        RGC_Data_Assets__c asset2 = new RGC_Data_Assets__c(Name = 'Asset 2');
        insert new List<RGC_Data_Assets__c>{asset1, asset2};

        // Step 2: Create FeedItem posts
        FeedItem oldPost1 = new FeedItem(
            ParentId = asset1.Id,
            Body = 'Old post for Asset 1',
            CreatedDate = System.now().addDays(-10)
        );
        FeedItem oldPost2 = new FeedItem(
            ParentId = asset2.Id,
            Body = 'Old post for Asset 2',
            CreatedDate = System.now().addDays(-5)
        );
        insert new List<FeedItem>{oldPost1, oldPost2};

        // Step 3: Add new FeedItems
        FeedItem newPost1 = new FeedItem(
            ParentId = asset1.Id,
            Body = 'Latest post for Asset 1',
            CreatedDate = System.now()
        );
        FeedItem newPost2 = new FeedItem(
            ParentId = asset2.Id,
            Body = 'Latest post for Asset 2',
            CreatedDate = System.now().addDays(-1)
        );
        insert new List<FeedItem>{newPost1, newPost2};

        // Step 4: Query updated RGC Data Asset records
        List<RGC_Data_Assets__c> updatedAssets = [
            SELECT Latest_Chatter_Post__c
            FROM RGC_Data_Assets__c
            WHERE Id IN :new List<Id>{asset1.Id, asset2.Id}
        ];

        // Step 5: Validate results
        System.assertEquals('Latest post for Asset 1', updatedAssets[0].Latest_Chatter_Post__c);
        System.assertEquals('Old post for Asset 2', updatedAssets[1].Latest_Chatter_Post__c);
    }
}
