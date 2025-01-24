// Anonymous Apex (Run in Developer Console)
Integer processedCount = 0;
Integer batchSize = 200;
Boolean hasMore = true;

while (hasMore) {
    List<RGC_Data_Assets__c> assetsBatch = [
        SELECT Id, Latest_Chatter_Post__c, Clinical_Informatics_Lead__c 
        FROM RGC_Data_Assets__c
        LIMIT :batchSize
        OFFSET :processedCount
    ];
    
    if (assetsBatch.isEmpty()) {
        hasMore = false;
        break;
    }
    
    Set<Id> assetIds = new Map<Id, RGC_Data_Assets__c>(assetsBatch).keySet();
    
    // CHANGED: Query additional fields for tracked changes
    Map<Id, FeedItem> latestFeedItems = new Map<Id, FeedItem>();
    for (FeedItem fi : [
        SELECT ParentId, Body, Type, CreatedDate, 
               FieldHistory, OldValue, NewValue  // Tracked change fields
        FROM FeedItem
        WHERE ParentId IN :assetIds
        ORDER BY CreatedDate DESC
    ]) {
        if (!latestFeedItems.containsKey(fi.ParentId)) {
            // NEW: Only consider valid posts
            Boolean isValidTrackedChange = fi.Type == 'TrackedChange' && 
                fi.FieldHistory.contains('Clinical_Informatics_Lead__c');
            
            if (fi.Type == 'TextPost' || isValidTrackedChange) {
                latestFeedItems.put(fi.ParentId, fi);
            }
        }
    }
    
    List<RGC_Data_Assets__c> updates = new List<RGC_Data_Assets__c>();
    for (RGC_Data_Assets__c asset : assetsBatch) {
        if (latestFeedItems.containsKey(asset.Id)) {
            FeedItem latest = latestFeedItems.get(asset.Id);
            String displayValue;
            
            // NEW: Handle tracked changes
            if (latest.Type == 'TrackedChange') {
                // Format: "Clinical Informatics Lead changed from Old Value to New Value"
                displayValue = 'Clinical Informatics Lead changed from ' +
                    (latest.OldValue != null ? String.valueOf(latest.OldValue) : 'null') +
                    ' to ' + 
                    (latest.NewValue != null ? String.valueOf(latest.NewValue) : 'null');
            } else {
                // Regular chatter post
                displayValue = latest.Body;
            }
            
            if (asset.Latest_Chatter_Post__c != displayValue) {
                updates.add(new RGC_Data_Assets__c(
                    Id = asset.Id,
                    Latest_Chatter_Post__c = displayValue
                ));
            }
        } else if (asset.Latest_Chatter_Post__c != null) {
            updates.add(new RGC_Data_Assets__c(
                Id = asset.Id,
                Latest_Chatter_Post__c = null
            ));
        }
    }
    
    if (!updates.isEmpty()) {
        update updates;
        System.debug('Processed ' + updates.size() + ' records in this batch');
    }
    
    processedCount += batchSize;
}
System.debug('Total records processed: ' + processedCount);