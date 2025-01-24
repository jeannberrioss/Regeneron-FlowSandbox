/* To handle existing records, you can use an anonymous Apex script to process all historical FeedItem records
and update the Latest_Chatter_Post__c field for RGC_DATA_ASSETS__c. Below are the steps and implementation: */

// Step 1: Query all RGC_DATA_ASSETS__c records
List<RGC_DATA_ASSETS__c> allAssets = [
    SELECT Id
    FROM RGC_DATA_ASSETS__c
];

// Step 2: Collect all ParentIds (RGC_DATA_ASSETS__c IDs)
Set<Id> parentIds = new Set<Id>();
for (RGC_DATA_ASSETS__c asset : allAssets) {
    parentIds.add(asset.Id);
}

// Step 3: Query historical FeedItems for these ParentIds
List<FeedItem> historicalFeedItems = [
    SELECT Id, Body, CreatedDate, ParentId
    FROM FeedItem
    WHERE ParentId IN :parentIds
];

// Step 4: Determine the latest FeedItem for each RGC_DATA_ASSETS__c record
Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();
for (FeedItem fi : historicalFeedItems) {
    if (!latestPosts.containsKey(fi.ParentId) || 
        fi.CreatedDate > latestPosts.get(fi.ParentId).CreatedDate) {
        latestPosts.put(fi.ParentId, fi);
    }
}

// Step 5: Update the Latest_Chatter_Post__c field on RGC_DATA_ASSETS__c
List<RGC_DATA_ASSETS__c> assetsToUpdate = new List<RGC_DATA_ASSETS__c>();
for (Id parentId : latestPosts.keySet()) {
    RGC_DATA_ASSETS__c asset = new RGC_DATA_ASSETS__c(
        Id = parentId,
        Latest_Chatter_Post__c = latestPosts.get(parentId).Body
    );
    assetsToUpdate.add(asset);
}

// Step 6: Perform the update
if (!assetsToUpdate.isEmpty()) {
    update assetsToUpdate;
}
