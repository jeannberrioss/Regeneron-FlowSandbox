trigger UpdateLatestChatterPost on FeedItem (after insert, after update) {
    // Map to track the most recent FeedItem for each RGC Data Asset
    Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();

    // Step 1: Gather new FeedItems
    for (FeedItem fi : Trigger.new) {
        if (fi.ParentId != null && fi.Parent.Type == 'RGC_Data_Assets__c') {
            if (!latestPosts.containsKey(fi.ParentId) ||
                fi.CreatedDate > latestPosts.get(fi.ParentId).CreatedDate) {
                latestPosts.put(fi.ParentId, fi);
            }
        }
    }

    // Step 2: Query historical FeedItems for these records
    Set<Id> parentIds = latestPosts.keySet();
    List<FeedItem> historicalFeedItems = [
        SELECT Id, Body, CreatedDate, ParentId
        FROM FeedItem
        WHERE ParentId IN :parentIds
    ];

    // Step 3: Determine the most recent FeedItem
    for (FeedItem historical : historicalFeedItems) {
        if (!latestPosts.containsKey(historical.ParentId) ||
            historical.CreatedDate > latestPosts.get(historical.ParentId).CreatedDate) {
            latestPosts.put(historical.ParentId, historical);
        }
    }

    // Step 4: Update the custom field on RGC Data Assets
    List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
    for (Id parentId : latestPosts.keySet()) {
        RGC_Data_Assets__c asset = new RGC_Data_Assets__c(
            Id = parentId,
            Latest_Chatter_Post__c = latestPosts.get(parentId).Body
        );
        assetsToUpdate.add(asset);
    }

    if (!assetsToUpdate.isEmpty()) {
        update assetsToUpdate;
    }
}
