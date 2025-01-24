// Anonymous Apex Script (Execute in Developer Console)
List<RGC_Data_Assets__c> assetsToUpdate = new List<RGC_Data_Assets__c>();

// 1. Query feed items with tracked changes (no field filtering in SOQL)
List<FeedItem> allFeedItems = [
    SELECT Id, ParentId, Body, Type, CreatedDate, 
    (SELECT OldValue, NewValue FROM FeedTrackedChanges)
    FROM FeedItem 
    WHERE Parent.Type = 'RGC_Data_Assets__c' 
    AND (Type = 'TextPost' OR Type = 'TrackedChange')
    ORDER BY CreatedDate DESC
];

// 2. Identify relevant changes and collect lead IDs
Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
Set<Id> leadIds = new Set<Id>();

for(FeedItem fi : allFeedItems) {
    if(fi.Type == 'TrackedChange') {
        Boolean isOurField = false;
        for(FeedTrackedChange ftc : fi.FeedTrackedChanges) {
            // Check if values are in RGC_Lead__c format
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
                // Not our field's change
            }
        }
        if(isOurField) validTrackedChanges.put(fi.ParentId, fi);
    }
}

// 3. Get lead names
Map<Id, RGC_Lead__c> leadMap = new Map<Id, RGC_Lead__c>([
    SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
]);

// 4. Process latest activities
Map<Id, FeedItem> latestActivities = new Map<Id, FeedItem>();
for(FeedItem fi : allFeedItems) {
    Id parentId = fi.ParentId;
    if(fi.Type == 'TrackedChange' && !validTrackedChanges.containsKey(parentId)) continue;
    
    if(!latestActivities.containsKey(parentId)) {
        latestActivities.put(parentId, fi);
    }
}

// 5. Build update records
for(Id parentId : latestActivities.keySet()) {
    FeedItem latest = latestActivities.get(parentId);
    String message;
    
    if(latest.Type == 'TextPost') {
        message = latest.Body;
    } else {
        for(FeedTrackedChange ftc : latest.FeedTrackedChanges) {
            try {
                Id oldId = (Id)ftc.OldValue;
                Id newId = (Id)ftc.NewValue;
                
                String oldName = (oldId != null && leadMap.containsKey(oldId)) 
                               ? leadMap.get(oldId).Name : 'None';
                String newName = (newId != null && leadMap.containsKey(newId)) 
                               ? leadMap.get(newId).Name : 'None';
                               
                message = 'Clinical Informatics Lead changed from ' + oldName + ' to ' + newName;
                break;
            } catch(Exception e) {
                // Skip non-matching changes
            }
        }
    }
    
    if(String.isNotBlank(message)) {
        assetsToUpdate.add(new RGC_Data_Assets__c(
            Id = parentId,
            Latest_Chatter_Post__c = message.abbreviate(255)
        ));
    }
}

// 6. Execute update with error handling
if(!assetsToUpdate.isEmpty()) {
    Database.SaveResult[] results = Database.update(assetsToUpdate, false);
    for(Database.SaveResult sr : results) {
        if(!sr.isSuccess()) {
            System.debug('Error updating record: ' + sr.getErrors()[0].getMessage());
        }
    }
    System.debug('Processed ' + assetsToUpdate.size() + ' records');
} else {
    System.debug('No records to update');
}