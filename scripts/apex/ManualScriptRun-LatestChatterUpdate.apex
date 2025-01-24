/* To handle existing records, you can use an anonymous Apex script to process all historical FeedItem records
and update the Latest_Chatter_Post__c field for RGC_DATA_ASSETS__c. Below are the steps and implementation: */

// Anonymous Apex (Run in Developer Console)
Integer processedCount = 0;
Integer batchSize = 200; 
Boolean hasMore = true;

while (hasMore) {
    // FIX 1: Include Latest_Chatter_Post__c in the query
    List<RGC_Data_Assets__c> assetsBatch = [
        SELECT Id, Latest_Chatter_Post__c // Added missing field
        FROM RGC_Data_Assets__c
        LIMIT :batchSize
        OFFSET :processedCount
    ];
    
    if (assetsBatch.isEmpty()) {
        hasMore = false;
        break;
    }
    
    Set<Id> assetIds = new Map<Id, RGC_Data_Assets__c>(assetsBatch).keySet();
    
    // Get latest FeedItem per asset
    Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();
    for (FeedItem fi : [
        SELECT ParentId, Body, CreatedDate
        FROM FeedItem
        WHERE ParentId IN :assetIds
        ORDER BY CreatedDate DESC
    ]) {
        if (!latestPosts.containsKey(fi.ParentId)) {
            latestPosts.put(fi.ParentId, fi);
        }
    }
    
    // Prepare updates
    List<RGC_Data_Assets__c> updates = new List<RGC_Data_Assets__c>();
    for (RGC_Data_Assets__c asset : assetsBatch) {
        if (latestPosts.containsKey(asset.Id)) {
            String latestBody = latestPosts.get(asset.Id).Body;
            // FIX 2: Now asset.Latest_Chatter_Post__c is accessible
            if (asset.Latest_Chatter_Post__c != latestBody) { 
                updates.add(new RGC_Data_Assets__c(
                    Id = asset.Id,
                    Latest_Chatter_Post__c = latestBody
                ));
            }
        } else if (asset.Latest_Chatter_Post__c != null) {
            updates.add(new RGC_Data_Assets__c(
                Id = asset.Id,
                Latest_Chatter_Post__c = null
            ));
        }
    }
    
    // Execute update
    if (!updates.isEmpty()) {
        update updates;
        System.debug('Processed ' + updates.size() + ' records in this batch');
    }
    
    processedCount += batchSize;
}
System.debug('Total records processed: ' + processedCount);