// Trigger File: RGCDataAssetFeedTrigger.trigger
trigger RGCDataAssetFeedTrigger on FeedItem (after insert, after update, after delete) {
    RGCDataAssetFeedTriggerHandler handler = new RGCDataAssetFeedTriggerHandler();
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.afterDelete(Trigger.old);
        }
    }
}