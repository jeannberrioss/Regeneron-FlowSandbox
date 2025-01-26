trigger FeedItemTrigger on FeedItem (after insert, after update) {
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        FeedItemHandler.processFeedItems(Trigger.new);
    }
}