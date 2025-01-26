public class FeedItemHandler {
    public static void processFeedItems(List<FeedItem> newFeedItems) {
        Set<Id> parentAssetIds = new Set<Id>();
        Set<Id> relevantFeedItemIds = new Set<Id>();
        
        // Identify relevant feed items (1st filter)
        for(FeedItem fi : [
            SELECT Id, ParentId, Type 
            FROM FeedItem 
            WHERE Id IN :newFeedItems 
            AND Parent.Type = 'RGC_Data_Assets__c'
            AND Type IN ('TextPost','TrackedChange','LinkPost')
        ]) {
            parentAssetIds.add(fi.ParentId);
            relevantFeedItemIds.add(fi.Id);
        }
        
        if(parentAssetIds.isEmpty()) return;

        // Full query pattern from original code
        List<FeedItem> allFeedItems = [
            SELECT Id, ParentId, Body, Type, CreatedDate,
            (SELECT OldValue, NewValue FROM FeedTrackedChanges)
            FROM FeedItem 
            WHERE ParentId IN :parentAssetIds 
            AND Type IN ('TextPost','TrackedChange','LinkPost')
            ORDER BY CreatedDate DESC
        ];

        // Original processing logic
        Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
        Set<Id> leadIds = new Set<Id>();
        
        // TrackedChange validation
        for(FeedItem fi : allFeedItems) {
            if(fi.Type == 'TrackedChange') {
                Boolean isOurField = false;
                for(FeedTrackedChange ftc : fi.FeedTrackedChanges) {
                    try {
                        Id oldId = (Id)ftc.OldValue;
                        Id newId = (Id)ftc.NewValue;
                        
                        if(oldId?.getSobjectType() == RGC_Lead__c.SObjectType) {
                            leadIds.add(oldId);
                            isOurField = true;
                        }
                        if(newId?.getSobjectType() == RGC_Lead__c.SObjectType) {
                            leadIds.add(newId);
                            isOurField = true;
                        }
                    } catch(Exception e) { /* Non-ID field */ }
                }
                if(isOurField) validTrackedChanges.put(fi.ParentId, fi);
            }
        }

        // Lead mapping
        Map<Id, RGC_Lead__c> leadMap = new Map<Id, RGC_Lead__c>([
            SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
        ]);

        // Latest activity determination
        Map<Id, FeedItem> latestActivities = new Map<Id, FeedItem>();
        for(FeedItem fi : allFeedItems) {
            Id parentId = fi.ParentId;
            if(fi.Type == 'TrackedChange' && !validTrackedChanges.containsKey(parentId)) continue;
            
            if(!latestActivities.containsKey(parentId)) {
                latestActivities.put(parentId, fi);
            }
        }

        // Message construction
        List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
        for(Id parentId : latestActivities.keySet()) {
            FeedItem latest = latestActivities.get(parentId);
            String message;
            
            if(latest.Type == 'TextPost' || latest.Type == 'LinkPost') {
                message = latest.Body?.left(255); // Truncate to field length
            } 
            else if(latest.Type == 'TrackedChange') {
                for(FeedTrackedChange ftc : latest.FeedTrackedChanges) {
                    try {
                        Id oldId = (Id)ftc.OldValue;
                        Id newId = (Id)ftc.NewValue;
                        
                        String oldName = leadMap.get(oldId)?.Name ?? 'None';
                        String newName = leadMap.get(newId)?.Name ?? 'None';
                                       
                        message = 'Clinical Informatics Lead changed from ' + 
                                oldName + ' to ' + newName;
                        break;
                    } catch(Exception e) { /* Skip non-ID changes */ }
                }
            }
            
            if(String.isNotBlank(message)) {
                assetsToUpdate.add(new RGC_Data_Assets__c(
                    Id = parentId,
                    Latest_Chatter_Post__c = message
                ));
            }
        }

        // Update with error handling
        if(!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate, false);
        }
    }
}