public class FeedItemTriggerHandler {

    private static Map<Id, String> previousLatestChatterPosts = new Map<Id, String>(); // Map to store previous values

    public static void beforeInsert(List<FeedItem> newList) {
        // Logic for before insert event will go here
    }

    public static void afterInsert(List<FeedItem> newList) {
        handleAfterInsertAndUpdate(newList); // Reusing logic for insert
    }

    public static void beforeUpdate(List<FeedItem> oldList, List<FeedItem> newList) {
        // Logic for before update event will go here
    }

    public static void afterUpdate(List<FeedItem> oldList, List<FeedItem> newList) {
        handleAfterInsertAndUpdate(newList); // Reusing logic for update
    }

    public static void beforeDelete(List<FeedItem> oldList) {
        storePreviousChatterPosts(oldList); // Calling helper method for beforeDelete logic
    }

    public static void afterDelete(List<FeedItem> oldList) {
        handleAfterDelete(oldList); // Calling helper method for afterDelete logic
    }

    // --- Helper Method to handle After Insert and After Update logic ---
    private static void handleAfterInsertAndUpdate(List<FeedItem> feedItems) {
        // ... (Existing handleAfterInsertAndUpdate method from Step 2 & 3 - no changes here) ...
        Set<Id> parentIds = new Set<Id>();
        for (FeedItem fi : feedItems) {
            if (fi.Type == 'TextPost' && fi.ParentId != null) {
                parentIds.add(fi.ParentId);
            }
        }

        if (!parentIds.isEmpty()) {
            List<RGC_Data_Assets__c> assets = [
                SELECT Id, Latest_Chatter_Post__c
                FROM RGC_Data_Assets__c
                WHERE Id IN :parentIds
            ];

            Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();
            for (FeedItem fi : [
                SELECT ParentId, Body, CreatedDate
                FROM FeedItem
                WHERE ParentId IN :parentIds AND Type = 'TextPost'
                ORDER BY CreatedDate DESC
            ]) {
                if (!latestPosts.containsKey(fi.ParentId)) {
                    latestPosts.put(fi.ParentId, fi);
                }
            }

            List<RGC_Data_Assets__c> updates = new List<RGC_Data_Assets__c>();
            for (RGC_Data_Assets__c asset : assets) {
                if (latestPosts.containsKey(asset.Id)) {
                    String latestBody = latestPosts.get(asset.Id).Body;
                    if (asset.Latest_Chatter_Post__c != latestBody) {
                        updates.add(new RGC_Data_Assets__c(
                            Id = asset.Id,
                            Latest_Chatter_Post__c = latestBody
                        ));
                    }
                } else if (asset.Latest_Chatter_Post__c != null) {
                    updates.add(new RGC_Data_Assets__c(
                        Id = asset.Id,
                        Latest_Chatter_Post__c = null
                    ));
                }
            }

            if (!updates.isEmpty()) {
                update updates;
            }
        }
    }

    // --- Helper Method to handle Before Delete logic ---
    private static void storePreviousChatterPosts(List<FeedItem> feedItems) {
        // ... (Existing storePreviousChatterPosts method from Step 3 - no changes here) ...
        Set<Id> parentIds = new Set<Id>();
        for (FeedItem fi : feedItems) {
            if (fi.Type == 'TextPost' && fi.ParentId != null) {
                parentIds.add(fi.ParentId);
            }
        }

        if (!parentIds.isEmpty()) {
            List<RGC_Data_Assets__c> assets = [
                SELECT Id, Latest_Chatter_Post__c
                FROM RGC_Data_Assets__c
                WHERE Id IN :parentIds
            ];

            for (RGC_Data_Assets__c asset : assets) {
                previousLatestChatterPosts.put(asset.Id, asset.Latest_Chatter_Post__c);
            }
        }
    }

    // --- Helper Method to handle After Delete logic ---
     private static void handleAfterDelete(List<FeedItem> feedItems) {
        Set<Id> parentIds = new Set<Id>();
        for (FeedItem fi : feedItems) {
            if (fi.Type == 'TextPost' && fi.ParentId != null) {
                parentIds.add(fi.ParentId);
            }
        }

        if (!parentIds.isEmpty()) {
            Map<Id, String> previousPostsMap = previousLatestChatterPosts; // Get the map from beforeDelete
            Map<Id, FeedItem> latestPostsAfterDelete = new Map<Id, FeedItem>();
            List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();

            // Re-query for the latest TextPosts AFTER deletion
            for (FeedItem fi : [
                SELECT ParentId, Body, CreatedDate
                FROM FeedItem
                WHERE ParentId IN :parentIds AND Type = 'TextPost'
                ORDER BY CreatedDate DESC
            ]) {
                if (!latestPostsAfterDelete.containsKey(fi.ParentId)) {
                    latestPostsAfterDelete.put(fi.ParentId, fi);
                }
            }

            List<RGC_Data_Assets__c> assets = [
                SELECT Id, Latest_Chatter_Post__c
                FROM RGC_Data_Assets__c
                WHERE Id IN :parentIds
            ];

            for (RGC_Data_Assets__c asset : assets) {
                String previousPost = previousPostsMap.get(asset.Id); // Retrieve previous value

                if (latestPostsAfterDelete.containsKey(asset.Id)) {
                    // There are still TextPosts after deletion, update to the latest
                    String latestBody = latestPostsAfterDelete.get(asset.Id).Body;
                    if (asset.Latest_Chatter_Post__c != latestBody) {
                        assetsToUpdate.add(new RGC_Data_Assets__c(
                            Id = asset.Id,
                            Latest_Chatter_Post__c = latestBody
                        ));
                    }
                } else {
                    // No TextPosts remaining after deletion - ALWAYS set to NULL
                    assetsToUpdate.add(new RGC_Data_Assets__c(
                        Id = asset.Id,
                        Latest_Chatter_Post__c = null
                    ));
                }
            }

            if (!assetsToUpdate.isEmpty()) {
                update assetsToUpdate;
            }
        }
        previousLatestChatterPosts.clear(); // Clear the map after processing
    }
 }