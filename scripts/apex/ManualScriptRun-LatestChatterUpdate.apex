/* To handle existing records, you can use an anonymous Apex script to process all historical FeedItem records
and update the Latest_Chatter_Post__c field for RGC_DATA_ASSETS__c. Below are the steps and implementation: */

// Step 1: Query all RGC_DATA_ASSETS__c records
// Step 1: Query all RGC_DATA_ASSETS__c records
List<RGC_Data_Assets__c> allAssets = [
    SELECT Id, Latest_Chatter_Post__c
    FROM RGC_Data_Assets__c
];

// Step 2: Collect all ParentIds (RGC_DATA_ASSETS__c IDs)
Set<Id> parentIds = new Set<Id>();
for (RGC_Data_Assets__c asset : allAssets) {
    parentIds.add(asset.Id);
}

// Step 3: Query historical FeedItems for these ParentIds
List<FeedItem> historicalFeedItems = [
    SELECT Id, Body, CreatedDate, ParentId
    FROM FeedItem
    WHERE ParentId IN :parentIds
    ORDER BY ParentId, CreatedDate DESC
];

// Step 4: Determine the latest FeedItem for each RGC_DATA_ASSETS__c record
Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();
for (FeedItem fi : historicalFeedItems) {
    if (!latestPosts.containsKey(fi.ParentId)) { 
        // Since FeedItems are sorted by CreatedDate DESC, the first one is the latest
        latestPosts.put(fi.ParentId, fi);
    }
}

// Step 5: Update the Latest_Chatter_Post__c field on RGC_DATA_ASSETS__c
List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
for (RGC_Data_Assets__c asset : allAssets) {
    if (latestPosts.containsKey(asset.Id)) {
        FeedItem latestPost = latestPosts.get(asset.Id);
        if (asset.Latest_Chatter_Post__c != latestPost.Body) {
            // Update only if the latest post is different
            asset.Latest_Chatter_Post__c = latestPost.Body;
            assetsToUpdate.add(asset);
        }
    }
}

// Step 6: Perform the update
if (!assetsToUpdate.isEmpty()) {
    update assetsToUpdate;
}
