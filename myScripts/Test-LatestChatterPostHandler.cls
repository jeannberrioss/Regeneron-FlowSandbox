public class LatestChatterPostHandler {

// Method to handle insert/update of FeedItems
public static void updateLatestChatterPost(List<FeedItem> feedItems) {
    Set<Id> contactIds = new Set<Id>();
    for (FeedItem fi : feedItems) {
        contactIds.add(fi.ParentId);
    }

    Map<Id, FeedItem> latestPosts = getLatestTextPosts(contactIds);
    List<Contact> contactsToUpdate = new List<Contact>();
    for (Id contactId : latestPosts.keySet()) {
        FeedItem post = latestPosts.get(contactId);
        if (String.isNotBlank(post.Body)) {
            contactsToUpdate.add(new Contact(
                Id = contactId,
                Latest_Chatter_Post__c = post.Body
            ));
        }
    }
    updateContacts(contactsToUpdate);
}

// Method to handle deletion of FeedItems
public static void handleDeletedFeedItems(Set<Id> contactIds) {
    Map<Id, FeedItem> latestPosts = getLatestTextPosts(contactIds);
    List<Contact> contactsToUpdate = new List<Contact>();

    // Process ALL contactIds (even those without posts)
    for (Id contactId : contactIds) {
        if (latestPosts.containsKey(contactId)) {
            FeedItem post = latestPosts.get(contactId);
            contactsToUpdate.add(new Contact(
                Id = contactId,
                Latest_Chatter_Post__c = post.Body
            ));
        } else {
            contactsToUpdate.add(new Contact(
                Id = contactId,
                Latest_Chatter_Post__c = null
            ));
        }
    }
    updateContacts(contactsToUpdate);
}

// Helper method to query the latest TextPost for each Contact
private static Map<Id, FeedItem> getLatestTextPosts(Set<Id> contactIds) {
    Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();
    for (FeedItem fi : [
        SELECT Id, ParentId, Body, CreatedDate
        FROM FeedItem 
        WHERE ParentId IN :contactIds 
        AND Type = 'TextPost'
        ORDER BY CreatedDate DESC LIMIT 1
    ]) {
        if (!latestPosts.containsKey(fi.ParentId)) {
            latestPosts.put(fi.ParentId, fi);
        }
    }
    return latestPosts;
}

// Helper method to update Contacts with error handling
private static void updateContacts(List<Contact> contactsToUpdate) {
    if (!contactsToUpdate.isEmpty()) {
        Database.SaveResult[] results = Database.update(contactsToUpdate, false);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                System.debug('Error updating record: ' + sr.getErrors()[0].getMessage());
            }
        }
        System.debug('Processed ' + contactsToUpdate.size() + ' records');
    } else {
        System.debug('No records to update');
    }
}
}