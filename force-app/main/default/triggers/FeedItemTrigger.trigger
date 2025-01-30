trigger FeedItemTrigger on FeedItem (after insert, after update, after delete, before delete, before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        FeedItemTriggerHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        FeedItemTriggerHandler.afterInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        FeedItemTriggerHandler.beforeUpdate(Trigger.old, Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        FeedItemTriggerHandler.afterUpdate(Trigger.old, Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
        FeedItemTriggerHandler.beforeDelete(Trigger.old);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        FeedItemTriggerHandler.afterDelete(Trigger.old);
    }
}