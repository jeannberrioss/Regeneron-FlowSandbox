// This trigger will fire when = after insert, after update, after delete
trigger FeedItemTrigger on FeedItem (
    after insert, after update, after delete
) {
    Set<Id> parentIds = new Set<Id>();
    String rgcPrefix = RGC_Data_Assets__c.SObjectType.getDescribe().getKeyPrefix();
    
    // Handle insert/update
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (FeedItem fi : Trigger.new) {
            String parentIdPrefix = String.valueOf(fi.ParentId).substring(0, 3);
            if (parentIdPrefix == rgcPrefix) {
                parentIds.add(fi.ParentId);
            }
        }
    }
    
    // Handle delete (check if deleted FeedItem was the latest)
    if (Trigger.isDelete) {
        for (FeedItem fi : Trigger.old) {
            String parentIdPrefix = String.valueOf(fi.ParentId).substring(0, 3);
            if (parentIdPrefix == rgcPrefix) {
                parentIds.add(fi.ParentId);
            }
        }
    }
    
    if (!parentIds.isEmpty()) {
        Map<Id, FeedItem> latestFeedItems = new Map<Id, FeedItem>();
        for (FeedItem fi : [
            SELECT Id, ParentId, Body, CreatedDate
            FROM FeedItem
            WHERE ParentId IN :parentIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!latestFeedItems.containsKey(fi.ParentId)) {
                latestFeedItems.put(fi.ParentId, fi);
            }
        }
        
        List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
        for (Id parentId : parentIds) {
            if (latestFeedItems.containsKey(parentId)) {
                // Update with latest post (if any)
                FeedItem latest = latestFeedItems.get(parentId);
                assetsToUpdate.add(new RGC_Data_Assets__c(
                    Id = parentId,
                    Latest_Chatter_Post__c = latest.Body
                ));
            } else {
                // No FeedItems left ➔ clear the field
                assetsToUpdate.add(new RGC_Data_Assets__c(
                    Id = parentId,
                    Latest_Chatter_Post__c = null
                ));
            }
        }
        
        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
    }
}