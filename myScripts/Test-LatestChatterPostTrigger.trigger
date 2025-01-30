trigger LatestChatterPostTrigger on FeedItem (after insert, after update, after delete) {
    // For insert and update events
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // Check if the FeedItem is of type 'TextPost' and related to a Contact
        List<FeedItem> contactTextPosts = new List<FeedItem>();
        for (FeedItem fi : Trigger.new) {
            if (fi.Type == 'TextPost' && fi.ParentId != null && String.valueOf(fi.ParentId).startsWith('003')) {
                contactTextPosts.add(fi);
            }
        }

        // Call the handler if there are relevant FeedItems
        if (!contactTextPosts.isEmpty()) {
            LatestChatterPostHandler.updateLatestChatterPost(contactTextPosts);
        }
    }

    // For delete events
    if (Trigger.isAfter && Trigger.isDelete) {
        // Check if the deleted FeedItem is of type 'TextPost' and related to a Contact
        Set<Id> contactIds = new Set<Id>();
        for (FeedItem fi : Trigger.old) {
            if (fi.Type == 'TextPost' && fi.ParentId != null && String.valueOf(fi.ParentId).startsWith('003')) {
                contactIds.add(fi.ParentId);
            }
        }

        // Call the handler if there are relevant FeedItems
        if (!contactIds.isEmpty()) {
            LatestChatterPostHandler.handleDeletedFeedItems(contactIds);
        }
    }
}