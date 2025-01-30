/*

Anonymous Apex (Run in Developer Console) 

1. This code should trigger ONLY IF the FeedItem 'TextPost' type has been updated, insered or deleted on a 'RGC_Data_Assets__c' record.
2. Once triggered, this code should query the 'RGC_Data_Assets__c' record that was updated, inserted or deleted to obtain the latest 'TextPost' FeedItem.
3. Then, depending on the context event (AfterUpdate, AfterInsert, AfterDelete), the code should update the 'Latest_Chatter_Post__c' field on the 'RGC_Data_Assets__c' record with the latest 'TextPost' FeedItem value.
4. It is important to remember that IF the 'TextPost' FeedItem is deleted on a record, the 'Latest_Chatter_Post__c' field should be set to the value that it had before the 'TextPost' FeedItem was deleted.
5. It is also importent to rememebr that IF the 'TextPost' FeedItem is deleted on a record && there is no other 'TextPost' FeedItem on the record, the 'Latest_Chatter_Post__c' field should be set to NULL.

*/

trigger FeedItemTrigger on FeedItem (after insert, after update, after delete) {
    Set<Id> parentIds = new Set<Id>();
    
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (FeedItem fi : Trigger.new) {
            if (fi.Type == 'TextPost' && fi.ParentId != null) {
                parentIds.add(fi.ParentId);
            }
        }
    }
    
    if (Trigger.isDelete) {
        for (FeedItem fi : Trigger.old) {
            if (fi.Type == 'TextPost' && fi.ParentId != null) {
                parentIds.add(fi.ParentId);
            }
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