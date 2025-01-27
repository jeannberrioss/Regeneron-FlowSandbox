public class FeedItemHandler {
    
    // This method processes FeedItems and updates the Latest_Chatter_Post__c field on RGC_Data_Assets__c records.
    public static void processFeedItems(List<FeedItem> feedItems, Map<Id, FeedItem> oldFeedItemsMap, Boolean isDelete) {
        Set<Id> parentAssetIds = new Set<Id>();
        Set<Id> feedItemIds = new Set<Id>();
        Set<String> validPostTypes = new Set<String>{'TextPost', 'TrackedChange', 'LinkPost'}; // Define valid types
        
        // Extract FeedItem IDs for the SOQL query
        for (FeedItem fi : feedItems) {
            feedItemIds.add(fi.Id);
        }
        
        // Identify relevant feed items (1st filter)
        for (FeedItem fi : [
            SELECT Id, ParentId, Type 
            FROM FeedItem 
            WHERE Id IN :feedItemIds
            AND Parent.Type = 'RGC_Data_Assets__c'
            AND Type IN :validPostTypes // Use the Set here for SOQL
        ]) {
            parentAssetIds.add(fi.ParentId);
        }
        
        // If it's a delete operation, check old FeedItems
        if (isDelete && oldFeedItemsMap != null) {
            for (FeedItem fi : oldFeedItemsMap.values()) {
                // Use validPostTypes.contains() instead of IN for Apex logic
                if (fi.Parent.Type == 'RGC_Data_Assets__c' && validPostTypes.contains(fi.Type)) {
                    parentAssetIds.add(fi.ParentId);
                }
            }
        }
        
        // Exit if no relevant parent assets are found
        if (parentAssetIds.isEmpty()) return;

        // Query all relevant FeedItems for the parent assets
        List<FeedItem> allFeedItems = [
            SELECT Id, ParentId, Body, Type, CreatedDate,
            (SELECT OldValue, NewValue FROM FeedTrackedChanges)
            FROM FeedItem 
            WHERE ParentId IN :parentAssetIds 
            AND Type IN :validPostTypes // Use the Set here for SOQL
            ORDER BY CreatedDate DESC
        ];

        // TrackedChange validation
        Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
        Set<Id> leadIds = new Set<Id>();
        
        for (FeedItem fi : allFeedItems) {
            if (fi.Type == 'TrackedChange') {
                Boolean isOurField = false;
                for (FeedTrackedChange ftc : fi.FeedTrackedChanges) {
                    try {
                        Id oldId = (Id) ftc.OldValue;
                        Id newId = (Id) ftc.NewValue;
                        
                        if (oldId?.getSobjectType() == RGC_Lead__c.SObjectType) {
                            leadIds.add(oldId);
                            isOurField = true;
                        }
                        if (newId?.getSobjectType() == RGC_Lead__c.SObjectType) {
                            leadIds.add(newId);
                            isOurField = true;
                        }
                    } catch (Exception e) { /* Skip non-ID fields */ }
                }
                if (isOurField) validTrackedChanges.put(fi.ParentId, fi);
            }
        }

        // Query RGC_Lead__c records for mapping
        Map<Id, RGC_Lead__c> leadMap = new Map<Id, RGC_Lead__c>([
            SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
        ]);

        // Determine the latest FeedItem for each parent asset
        Map<Id, FeedItem> latestActivities = new Map<Id, FeedItem>();
        for (FeedItem fi : allFeedItems) {
            Id parentId = fi.ParentId;
            if (fi.Type == 'TrackedChange' && !validTrackedChanges.containsKey(parentId)) continue;
            
            if (!latestActivities.containsKey(parentId)) {
                latestActivities.put(parentId, fi);
            }
        }

        // Construct the message and prepare RGC_Data_Assets__c records for update
        List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
        for (Id parentId : latestActivities.keySet()) {
            FeedItem latest = latestActivities.get(parentId);
            String message;
            
            if (latest.Type == 'TextPost' || latest.Type == 'LinkPost') {
                message = latest.Body?.left(255); // Truncate to field length
            } else if (latest.Type == 'TrackedChange') {
                for (FeedTrackedChange ftc : latest.FeedTrackedChanges) {
                    try {
                        Id oldId = (Id) ftc.OldValue;
                        Id newId = (Id) ftc.NewValue;
                        
                        String oldName = leadMap.get(oldId)?.Name ?? 'None';
                        String newName = leadMap.get(newId)?.Name ?? 'None';
                                       
                        message = 'Clinical Informatics Lead changed from ' + 
                                oldName + ' to ' + newName;
                        break;
                    } catch (Exception e) { /* Skip non-ID changes */ }
                }
            }
            
            if (String.isNotBlank(message)) {
                assetsToUpdate.add(new RGC_Data_Assets__c(
                    Id = parentId,
                    Latest_Chatter_Post__c = message
                ));
            }
        }

        // Update RGC_Data_Assets__c records with error handling
        if (!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate, false);
        }
    }
}