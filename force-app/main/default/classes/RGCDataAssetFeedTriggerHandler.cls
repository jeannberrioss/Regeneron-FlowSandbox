// Handler Class: RGCDataAssetFeedTriggerHandler.cls
public with sharing class RGCDataAssetFeedTriggerHandler {
    public void afterInsert(List<FeedItem> newList) {
        processFeedItems(getParentIds(newList));
    }

    public void afterUpdate(List<FeedItem> newList, Map<Id, FeedItem> oldMap) {
        processFeedItems(getParentIds(newList));
    }

    public void afterDelete(List<FeedItem> oldList) {
        processFeedItems(getParentIds(oldList));
    }

    private Set<Id> getParentIds(List<FeedItem> items) {
        Set<Id> parentIds = new Set<Id>();
        for (FeedItem fi : items) {
            parentIds.add(fi.ParentId);
        }
        return parentIds;
    }

    private void processFeedItems(Set<Id> parentIds) {
        if (!parentIds.isEmpty()) {
            RGCDataAssetFeedHelper.processLatestChatterPosts(parentIds);
        }
    }
}