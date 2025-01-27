// Goal = Collect all historical FeedItems of type = TextPost for Contacts SObject.
// Once collected, we will update the Latest_Chatter_Post__c custom field
// on the Contact record with the latest post message.

// Anonymous Apex Script (Execute in Developer Console)
List<Contact> contactsToUpdate = new List<Contact>();

// 1. Query only TextPost feed items for Contacts
List<FeedItem> contactFeedItems = [
    SELECT Id, ParentId, Body, CreatedDate
    FROM FeedItem 
    WHERE Parent.Type = 'Contact' 
    AND Type = 'TextPost'
    ORDER BY CreatedDate DESC
];

// 2. Collect latest post per Contact
Map<Id, FeedItem> latestPosts = new Map<Id, FeedItem>();
for(FeedItem fi : contactFeedItems) {
    if(!latestPosts.containsKey(fi.ParentId)) {
        latestPosts.put(fi.ParentId, fi);
    }
}

// 3. Build update records with post messages
for(Id contactId : latestPosts.keySet()) {
    FeedItem post = latestPosts.get(contactId);
    if(String.isNotBlank(post.Body)) {
        contactsToUpdate.add(new Contact(
            Id = contactId,
            Latest_Chatter_Post__c = post.Body
        ));
    }
}

// 4. Execute update with error handling
if(!contactsToUpdate.isEmpty()) {
    Database.SaveResult[] results = Database.update(contactsToUpdate, false);
    for(Database.SaveResult sr : results) {
        if(!sr.isSuccess()) {
            System.debug('Error updating record: ' + sr.getErrors()[0].getMessage());
        }
    }
    System.debug('Processed ' + contactsToUpdate.size() + ' records');
} else {
    System.debug('No records to update');
}