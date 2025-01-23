trigger UpdateLatestChatterPost on FeedItem (after insert) {
    // Map to store the latest post for each A1 record
    Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();

    // Step 1: Query existing FeedItems for relevant A1 records
    Set<Id> parentIds = new Set<Id>();
    for (FeedItem fi : Trigger.new) {
        if (fi.ParentId != null && fi.Parent.Type == 'A1') {
            parentIds.add(fi.ParentId);
        }
    }

    if (!parentIds.isEmpty()) {
        List<FeedItem> existingPosts = [
            SELECT Id, ParentId, CreatedDate, Body
            FROM FeedItem
            WHERE ParentId IN :parentIds
        ];

        // Add existing FeedItems to the map
        for (FeedItem fi : existingPosts) {
            if (!latestPosts.containsKey(fi.ParentId) ||
                fi.CreatedDate > latestPosts.get(fi.ParentId).CreatedDate) {
                latestPosts.put(fi.ParentId, fi);
            }
        }
    }

    // Step 2: Process new FeedItems in Trigger.new
    for (FeedItem fi : Trigger.new) {
        if (fi.ParentId != null && fi.Parent.Type == 'A1') {
            if (!latestPosts.containsKey(fi.ParentId) ||
                fi.CreatedDate > latestPosts.get(fi.ParentId).CreatedDate) {
                latestPosts.put(fi.ParentId, fi);
            }
        }
    }

    // Step 3: Update parent A1 records
    List<A1__c> recordsToUpdate = new List<A1__c>();
    for (Id parentId : latestPosts.keySet()) {
        FeedItem latestPost = latestPosts.get(parentId);
        recordsToUpdate.add(new A1__c(
            Id = parentId,
            Latest_Chatter_Post_Content__c = latestPost.Body,
            Latest_Chatter_Post_Date__c = latestPost.CreatedDate
        ));
    }

    if (!recordsToUpdate.isEmpty()) {
        update recordsToUpdate;
    }
}
