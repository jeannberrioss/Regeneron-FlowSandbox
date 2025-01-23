@isTest
public class UpdateLatestChatterPostTest {
    @isTest
    static void testLatestChatterPost() {
        // Step 1: Create test data - A1 parent records
        A1__c parent1 = new A1__c(Name = 'Parent Record 1');
        A1__c parent2 = new A1__c(Name = 'Parent Record 2');
        insert new List<A1__c>{parent1, parent2};

        // Step 2: Create existing FeedItems for the parent records
        FeedItem oldPost1 = new FeedItem(
            ParentId = parent1.Id,
            Body = 'Old post for Parent 1',
            CreatedDate = System.now().addDays(-10)
        );
        FeedItem oldPost2 = new FeedItem(
            ParentId = parent2.Id,
            Body = 'Old post for Parent 2',
            CreatedDate = System.now().addDays(-8)
        );
        insert new List<FeedItem>{oldPost1, oldPost2};

        // Step 3: Create new FeedItems (simulating Trigger.new)
        FeedItem newPost1 = new FeedItem(
            ParentId = parent1.Id,
            Body = 'Latest post for Parent 1',
            CreatedDate = System.now()
        );
        FeedItem newPost2 = new FeedItem(
            ParentId = parent2.Id,
            Body = 'Latest post for Parent 2',
            CreatedDate = System.now().addDays(-1)
        );
        insert new List<FeedItem>{newPost1, newPost2};

        // Step 4: Query updated A1 records to validate results
        List<A1__c> updatedParents = [
            SELECT Latest_Chatter_Post_Content__c, Latest_Chatter_Post_Date__c
            FROM A1__c
            WHERE Id IN :new List<Id>{parent1.Id, parent2.Id}
        ];

        // Step 5: Assertions
        System.assertEquals('Latest post for Parent 1', updatedParents[0].Latest_Chatter_Post_Content__c, 'Parent 1 latest post content should be updated');
        System.assertEquals(newPost1.CreatedDate, updatedParents[0].Latest_Chatter_Post_Date__c, 'Parent 1 latest post date should be updated');

        System.assertEquals('Old post for Parent 2', updatedParents[1].Latest_Chatter_Post_Content__c, 'Parent 2 should still have the old post');
        System.assertEquals(oldPost2.CreatedDate, updatedParents[1].Latest_Chatter_Post_Date__c, 'Parent 2 should still have the old post date');
    }
}
