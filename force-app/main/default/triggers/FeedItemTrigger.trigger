trigger FeedItemTrigger on FeedItem (after insert, after update, after delete) {
    // Call the handler class to process FeedItems
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            FeedItemHandler.processFeedItems(Trigger.new, Trigger.oldMap, false);
        } else if (Trigger.isDelete) {
            FeedItemHandler.processFeedItems(Trigger.old, Trigger.oldMap, true);
        }
    }
}