trigger RGCDataAssetFeedTrigger on FeedItem (after insert, after update) {
    Set<Id> parentIds = new Set<Id>();
    List<FeedItem> relevantFeedItems = new List<FeedItem>();
    
    // Collect relevant FeedItems from Trigger.new
    for (FeedItem fi : Trigger.new) {
        if (fi.ParentId?.getSObjectType() == RGC_Data_Assets__c.SObjectType && 
            (fi.Type == 'TextPost' || fi.Type == 'TrackedChange')) {
            parentIds.add(fi.ParentId);
            relevantFeedItems.add(fi);
        }
    }
    
    if (parentIds.isEmpty()) return;
    
    // Query all FeedItems for the affected ParentIds
    Map<Id, List<FeedItem>> parentIdToFeedItems = new Map<Id, List<FeedItem>>();
    for (FeedItem fi : [
        SELECT Id, ParentId, Body, Type, CreatedDate, 
        (SELECT OldValue, NewValue FROM FeedTrackedChanges)
        FROM FeedItem 
        WHERE ParentId IN :parentIds 
        AND (Type = 'TextPost' OR Type = 'TrackedChange')
        ORDER BY CreatedDate DESC
    ]) {
        if (!parentIdToFeedItems.containsKey(fi.ParentId)) {
            parentIdToFeedItems.put(fi.ParentId, new List<FeedItem>());
        }
        parentIdToFeedItems.get(fi.ParentId).add(fi);
    }
    
    // Process to find latest FeedItem per ParentId
    Map<Id, FeedItem> latestFeedByParent = new Map<Id, FeedItem>();
    for (Id parentId : parentIdToFeedItems.keySet()) {
        List<FeedItem> feedItems = parentIdToFeedItems.get(parentId);
        if (!feedItems.isEmpty()) {
            latestFeedByParent.put(parentId, feedItems[0]); // Most recent due to ORDER BY
        }
    }
    
    // Collect Lead IDs and process messages
    Set<Id> leadIds = new Set<Id>();
    Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
    
    for (FeedItem fi : latestFeedByParent.values()) {
        if (fi.Type == 'TrackedChange') {
            for (FeedTrackedChange ftc : fi.FeedTrackedChanges) {
                try {
                    Id oldId = (Id) ftc.OldValue;
                    Id newId = (Id) ftc.NewValue;
                    
                    if (oldId?.getSObjectType() == RGC_Lead__c.SObjectType) leadIds.add(oldId);
                    if (newId?.getSObjectType() == RGC_Lead__c.SObjectType) leadIds.add(newId);
                } catch (Exception e) {}
            }
            validTrackedChanges.put(fi.ParentId, fi);
        }
    }
    
    // Query Lead names
    Map<Id, RGC_Lead__c> leadMap = new Map<Id, RGC_Lead__c>([
        SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
    ]);
    
    // Build updates
    List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
    for (Id parentId : latestFeedByParent.keySet()) {
        FeedItem latest = latestFeedByParent.get(parentId);
        String message;
        
        if (latest.Type == 'TextPost') {
            message = latest.Body;
        } else if (validTrackedChanges.containsKey(parentId)) {
            for (FeedTrackedChange ftc : latest.FeedTrackedChanges) {
                try {
                    Id oldId = (Id) ftc.OldValue;
                    Id newId = (Id) ftc.NewValue;
                    
                    String oldName = (oldId != null && leadMap.containsKey(oldId)) 
                                   ? leadMap.get(oldId).Name : 'None';
                    String newName = (newId != null && leadMap.containsKey(newId)) 
                                   ? leadMap.get(newId).Name : 'None';
                    message = 'Clinical Informatics Lead changed from ' + oldName + ' to ' + newName;
                    break;
                } catch (Exception e) {}
            }
        }
        
        if (String.isNotBlank(message)) {
            assetsToUpdate.add(new RGC_Data_Assets__c(
                Id = parentId,
                Latest_Chatter_Post__c = message.abbreviate(255)
            ));
        }
    }
    
    // Update records
    if (!assetsToUpdate.isEmpty()) {
        update assetsToUpdate;
    }
}