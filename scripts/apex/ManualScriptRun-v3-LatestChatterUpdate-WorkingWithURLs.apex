// This code will process all historical FeedItem records and post most recent change to LCP custom field.
// but include checks for these FeedItem 'Types' = TextPost,TrackedChange,LinkPost (URL Link Post)

List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();
List<FeedItem> allFeedItems = [
    SELECT Id, ParentId, Body, Type, CreatedDate,  // Removed LinkUrl/Title
    (SELECT OldValue, NewValue FROM FeedTrackedChanges)
    FROM FeedItem 
    WHERE Parent.Type = 'RGC_Data_Assets__c' 
    AND Type IN ('TextPost', 'TrackedChange', 'LinkPost')
    ORDER BY CreatedDate DESC
];

// TrackedChange handling (unchanged)
Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
Set<Id> leadIds = new Set<Id>();
for(FeedItem fi : allFeedItems) {
    if(fi.Type == 'TrackedChange') {
        Boolean isOurField = false;
        for(FeedTrackedChange ftc : fi.FeedTrackedChanges) {
            try {
                Id oldId = (Id)ftc.OldValue;
                Id newId = (Id)ftc.NewValue;
                
                if(oldId != null && oldId.getSobjectType() == RGC_Lead__c.SObjectType) {
                    leadIds.add(oldId);
                    isOurField = true;
                }
                if(newId != null && newId.getSobjectType() == RGC_Lead__c.SObjectType) {
                    leadIds.add(newId);
                    isOurField = true;
                }
            } catch(Exception e) {
                // Non-RGC Lead field change
            }
        }
        if(isOurField) validTrackedChanges.put(fi.ParentId, fi);
    }
}

Map<Id, RGC_Lead__c> leadMap = new Map<Id, RGC_Lead__c>([
    SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
]);

// Latest activity determination
Map<Id, FeedItem> latestActivities = new Map<Id, FeedItem>();
for(FeedItem fi : allFeedItems) {
    Id parentId = fi.ParentId;
    if(fi.Type == 'TrackedChange' && !validTrackedChanges.containsKey(parentId)) continue;
    
    if(!latestActivities.containsKey(parentId)) {
        latestActivities.put(parentId, fi);
    }
}

// Simplified message processing
for(Id parentId : latestActivities.keySet()) {
    FeedItem latest = latestActivities.get(parentId);
    String message;
    
    if(latest.Type == 'TextPost' || latest.Type == 'LinkPost') {  // Combined handling
        message = latest.Body;  // Direct body usage for both types
    } 
    else if(latest.Type == 'TrackedChange') {
        for(FeedTrackedChange ftc : latest.FeedTrackedChanges) {
            try {
                Id oldId = (Id)ftc.OldValue;
                Id newId = (Id)ftc.NewValue;
                
                String oldName = leadMap.containsKey(oldId) ? leadMap.get(oldId).Name : 'None';
                String newName = leadMap.containsKey(newId) ? leadMap.get(newId).Name : 'None';
                               
                message = 'Clinical Informatics Lead changed from ' + oldName + ' to ' + newName;
                break;
            } catch(Exception e) {
                // Skip non-ID changes
            }
        }
    }
    
    if(String.isNotBlank(message)) {
        assetsToUpdate.add(new RGC_Data_Assets__c(
            Id = parentId,
            Latest_Chatter_Post__c = message
        ));
    }
}

// Update logic remains unchanged
if(!assetsToUpdate.isEmpty()) {
    Database.SaveResult[] results = Database.update(assetsToUpdate, false);
    for(Database.SaveResult sr : results) {
        if(!sr.isSuccess()) {
            System.debug('Update error: ' + sr.getErrors()[0].getMessage());
        }
    }
    System.debug('Processed ' + assetsToUpdate.size() + ' records');
} else {
    System.debug('No updates required');
}