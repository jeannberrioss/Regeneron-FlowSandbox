// Helper Class: RGCDataAssetFeedHelper.cls
public with sharing class RGCDataAssetFeedHelper {
    public static void processLatestChatterPosts(Set<Id> parentIds) {
        List<FeedItem> relevantFeedItems = getRelevantFeedItems(parentIds);
        Map<Id, FeedItem> latestActivities = processFeedItems(relevantFeedItems);
        List<RGC_Data_Assets__c> assetsToUpdate = buildAssetUpdates(latestActivities);
        
        executeUpdates(assetsToUpdate);
    }

    private static List<FeedItem> getRelevantFeedItems(Set<Id> parentIds) {
        return [
            SELECT Id, ParentId, Body, Type, CreatedDate,
                (SELECT OldValue, NewValue FROM FeedTrackedChanges)
            FROM FeedItem 
            WHERE ParentId IN :parentIds
            AND Parent.Type = 'RGC_Data_Assets__c'
            AND Type IN ('TextPost', 'TrackedChange', 'LinkPost')
            ORDER BY CreatedDate DESC
        ];
    }

    private static Map<Id, FeedItem> processFeedItems(List<FeedItem> feedItems) {
        Map<Id, FeedItem> validTrackedChanges = new Map<Id, FeedItem>();
        Set<Id> leadIds = new Set<Id>();

        // Identify valid tracked changes
        for (FeedItem fi : feedItems) {
            if (fi.Type == 'TrackedChange') {
                processTrackedChange(fi, leadIds, validTrackedChanges);
            }
        }

        // Get lead mappings
        Map<Id, RGC_Lead__c> leadMap = getLeadMap(leadIds);

        // Determine latest activities
        return identifyLatestActivities(feedItems, validTrackedChanges, leadMap);
    }

    private static void processTrackedChange(FeedItem fi, Set<Id> leadIds, Map<Id, FeedItem> validTrackedChanges) {
        Boolean isRelevantChange = false;
        for (FeedTrackedChange ftc : fi.FeedTrackedChanges) {
            try {
                Id oldId = (Id)ftc.OldValue;
                Id newId = (Id)ftc.NewValue;
                
                if (isValidLeadId(oldId)) {
                    leadIds.add(oldId);
                    isRelevantChange = true;
                }
                if (isValidLeadId(newId)) {
                    leadIds.add(newId);
                    isRelevantChange = true;
                }
            } catch (Exception e) {
                // Ignore non-ID changes
            }
        }
        if (isRelevantChange) {
            validTrackedChanges.put(fi.ParentId, fi);
        }
    }

    private static Boolean isValidLeadId(Id recordId) {
        return recordId != null && recordId.getSobjectType() == RGC_Lead__c.SObjectType;
    }

    private static Map<Id, RGC_Lead__c> getLeadMap(Set<Id> leadIds) {
        return new Map<Id, RGC_Lead__c>([
            SELECT Id, Name FROM RGC_Lead__c WHERE Id IN :leadIds
        ]);
    }

    private static Map<Id, FeedItem> identifyLatestActivities(List<FeedItem> feedItems, Map<Id, FeedItem> validTrackedChanges, Map<Id, RGC_Lead__c> leadMap) {
        Map<Id, FeedItem> latestActivities = new Map<Id, FeedItem>();
        for (FeedItem fi : feedItems) {
            Id parentId = fi.ParentId;
            if (shouldSkipTrackedChange(fi, validTrackedChanges)) continue;
            
            if (!latestActivities.containsKey(parentId)) {
                latestActivities.put(parentId, fi);
            }
        }
        return latestActivities;
    }

    private static Boolean shouldSkipTrackedChange(FeedItem fi, Map<Id, FeedItem> validTrackedChanges) {
        return fi.Type == 'TrackedChange' && !validTrackedChanges.containsKey(fi.ParentId);
    }

    private static List<RGC_Data_Assets__c> buildAssetUpdates(Map<Id, FeedItem> latestActivities) {
        List<RGC_Data_Assets__c> updates = new List<RGC_Data_Assets__c>();
        for (Id parentId : latestActivities.keySet()) {
            String message = buildMessage(latestActivities.get(parentId));
            if (String.isNotBlank(message)) {
                updates.add(new RGC_Data_Assets__c(
                    Id = parentId,
                    Latest_Chatter_Post__c = message
                ));
            }
        }
        return updates;
    }

    private static String buildMessage(FeedItem latest) {
        if (latest.Type == 'TextPost' || latest.Type == 'LinkPost') {
            return latest.Body;
        }
        if (latest.Type == 'TrackedChange') {
            return processTrackedChangeMessage(latest);
        }
        return null;
    }

    private static String processTrackedChangeMessage(FeedItem latest) {
        for (FeedTrackedChange ftc : latest.FeedTrackedChanges) {
            try {
                Id oldId = (Id)ftc.OldValue;
                Id newId = (Id)ftc.NewValue;
                String oldName = getLeadName(oldId);
                String newName = getLeadName(newId);
                
                return 'Clinical Informatics Lead changed from ' + oldName + ' to ' + newName;
            } catch (Exception e) {
                // Skip non-ID changes
            }
        }
        return null;
    }

    private static String getLeadName(Id leadId) {
        return leadId != null ? [SELECT Name FROM RGC_Lead__c WHERE Id = :leadId].Name : 'None';
    }

    private static void executeUpdates(List<RGC_Data_Assets__c> assetsToUpdate) {
        if (!assetsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(assetsToUpdate, false);
            logResults(results);
        }
    }

    private static void logResults(Database.SaveResult[] results) {
        Integer successCount = 0;
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                System.debug('Update error: ' + sr.getErrors()[0].getMessage());
            } else {
                successCount++;
            }
        }
        System.debug('Successfully processed ' + successCount + ' records');
    }
}