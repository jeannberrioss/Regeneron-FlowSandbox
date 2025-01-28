public class FeedItemHandler {
    
    // Key prefix for RGC_Data_Assets__c (e.g., 'a01')
    private static final String DATA_ASSET_PREFIX = RGC_Data_Assets__c.SObjectType.getDescribe().getKeyPrefix();
    private static final Set<String> VALID_POST_TYPES = new Set<String>{'TextPost', 'TrackedChange', 'LinkPost'};
    
    // CRITICAL FIX: Field name in FeedTrackedChange uses "Clinical_Informatics_Lead" (no __c)
    private static final String TARGET_FIELD = 'Clinical_Informatics_Lead'; 

    public static void processFeedItems(List<FeedItem> feedItems, Map<Id, FeedItem> oldFeedItemsMap, Boolean isDelete) {
        Set<Id> parentAssetIds = new Set<Id>();
        
        // For DELETIONS: Collect ParentIds from old FeedItems
        if (isDelete && oldFeedItemsMap != null) {
            for (FeedItem fi : oldFeedItemsMap.values()) {
                if (String.valueOf(fi.ParentId).startsWith(DATA_ASSET_PREFIX) 
                    && VALID_POST_TYPES.contains(fi.Type)) {
                    parentAssetIds.add(fi.ParentId);
                }
            }
        } 
        // For INSERTS/UPDATES: Collect ParentIds from trigger FeedItems
        else {
            for (FeedItem fi : feedItems) {
                if (String.valueOf(fi.ParentId).startsWith(DATA_ASSET_PREFIX) 
                    && VALID_POST_TYPES.contains(fi.Type)) {
                    parentAssetIds.add(fi.ParentId);
                }
            }
        }
        
        if (parentAssetIds.isEmpty()) return;

        // Query all REMAINING FeedItems for parents (excluding deleted)
        List<FeedItem> allFeedItems = [
            SELECT Id, ParentId, Body, Type, CreatedDate,
            (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
            FROM FeedItem 
            WHERE ParentId IN :parentAssetIds 
            AND Type IN :VALID_POST_TYPES
            ORDER BY CreatedDate DESC
        ];

        // TrackedChange validation: Only process TARGET_FIELD changes
        Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
        Set<Id> leadIds = new Set<Id>();
        for (FeedItem fi : allFeedItems) {
            if (fi.Type == 'TrackedChange') {
                Boolean isOurField = false;
                for (FeedTrackedChange ftc : fi.FeedTrackedChanges) {
                    // Validate FieldName matches "Clinical_Informatics_Lead" (no __c)
                    if (ftc.FieldName != TARGET_FIELD) continue; 
                    
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
                    } catch (Exception e) { /* Skip non-ID values */ }
                }
                if (isOurField) validTrackedChanges.put(fi.ParentId, fi);
            }
        }

        // Lead mapping
        Map<Id, RGC_Lead__c> leadMap = new Map<Id, RGC_Lead__c>([
            SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
        ]);

        // Determine latest FeedItem per parent (prioritize valid TrackedChanges)
        Map<Id, FeedItem> latestActivities = new Map<Id, FeedItem>();
        for (FeedItem fi : allFeedItems) {
            Id parentId = fi.ParentId;
            // Skip invalid TrackedChanges or existing newer entries
            if (fi.Type == 'TrackedChange' && !validTrackedChanges.containsKey(parentId)) continue;
            if (!latestActivities.containsKey(parentId)) {
                latestActivities.put(parentId, fi);
            }
        }

        // Prepare updates for ALL parentAssetIds
        List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
        for (Id parentId : parentAssetIds) {
            String message;
            if (latestActivities.containsKey(parentId)) {
                FeedItem latest = latestActivities.get(parentId);
                if (latest.Type == 'TextPost' || latest.Type == 'LinkPost') {
                    message = latest.Body?.left(255);
                } else if (latest.Type == 'TrackedChange') {
                    // Iterate through TrackedChanges (only TARGET_FIELD changes exist here)
                    for (FeedTrackedChange ftc : latest.FeedTrackedChanges) {
                        if (ftc.FieldName != TARGET_FIELD) continue; 
                        try {
                            Id oldId = (Id) ftc.OldValue;
                            Id newId = (Id) ftc.NewValue;
                            String oldName = leadMap.get(oldId)?.Name ?? 'None';
                            String newName = leadMap.get(newId)?.Name ?? 'None';
                            message = 'Clinical Informatics Lead changed from ' + oldName + ' to ' + newName;
                            break; // Use first valid change
                        } catch (Exception e) { /* Skip non-ID values */ }
                    }
                }
            }
            // Update or clear the field
            assetsToUpdate.add(new RGC_Data_Assets__c(
                Id = parentId,
                Latest_Chatter_Post__c = String.isNotBlank(message) ? message : null
            ));
        }

        // Update records (allow partial success)
        if (!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate, false);
        }
    }
}