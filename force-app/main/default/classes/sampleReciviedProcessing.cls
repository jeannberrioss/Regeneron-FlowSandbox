public class sampleReciviedProcessing {
    @AuraEnabled
    public static paginationData sampleReciviedProcessingRecord(String csvString){
        
        String jsonDT = '';
        boolean isValidData = false;
        List<String> header = new List<String>();
        List < String > records = csvString.replaceAll('(\r\n|\r)','\n').split( '\n' );
        System.debug(records);
        header = records[0].split(',');
        records.remove( 0 );
        
        Set<String> KeyIds =  new Set<String>();
        
        Map<String,wrapperSample> mapRecord = new Map<String,wrapperSample>();
        for ( String record : records ) {
            System.debug('Inside record: '+record);
            List < String > row = record.split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)', -1);
            String Key;
            if((row[0] == null ||row[0] == '') || (row[2] == null || row[2] == '')){
                wrapperSample Res = new wrapperSample();
                Res.showError = true; 
            }else{
                system.debug('row 0 or 2 is Not null');
                Key  = row[0].trim() + row[2].trim();
                isValidData = true;
            }
            
           
            if(Key != null || Key != ''){
                system.debug('Key 28: '+Key);
                if(mapRecord.containsKey(Key)){
                    //merge the quantity
                    wrapperSample Res = mapRecord.get(Key);
                    system.debug('Res: '+Res);
                    Res.Quantity =  Res.Quantity + Integer.valueOf(row[3]);
                    system.debug('Quantity concate: '+Res.Quantity);
                    KeyIds.add(Key);
                }else{
                    system.debug('When key is null');
                    wrapperSample Res = new wrapperSample();
                    Res.Quantity = Integer.valueOf(row[3]);
                    Res.Project = row[1];
                    Res.Recivied_Date =  date.parse(row[2]);
                    Res.CollaboratorKey =  row[0];
                    mapRecord.put(Key,Res);
                    system.debug('When key null: '+mapRecord);
                    Res.key = row[0].trim() + row[2].trim();
                }
            }
            
            KeyIds.add(Key);
        }
        System.debug('KeyIds >>> '+KeyIds);
        Integer totalRecords = mapRecord.size();
        System.debug('mapSize / totalRecords: '+totalRecords);
        
        List<Sample_Received_Stage__c>  exestingRecord = New List<Sample_Received_Stage__c>();
        if(KeyIds.size() > 0){
            exestingRecord = [Select Id,Key__c ,Collaboration_Opportunity__c,Quantity__c 
                              from Sample_Received_Stage__c where Key__c in : KeyIds];
            system.debug('exestingRecord: '+exestingRecord);
        }
        if(exestingRecord.size() >0){
            for(Sample_Received_Stage__c record : exestingRecord){
                system.debug('existing Record: '+record);
                if(mapRecord.containsKey(record.Key__c)){
                    system.debug('existing record contains record key: ');
                    wrapperSample Res = mapRecord.get(record.Key__c);
                    system.debug('existing wrapper value: '+Res);
                    //Res.Quantity =  Res.Quantity + (Integer)record.Quantity__c;
                    system.debug('existing merged quantity: '+Res.Quantity);
                }
            }
        }
        System.debug('mapRecord 71: '+mapRecord);
        System.debug('mapRecord values 71: '+mapRecord.values());
       
        List<Sample_Received_Stage__c> Samplerecord = new List<Sample_Received_Stage__c>();
        
        Set<String> keySet = new Set<String>();
            
        for ( wrapperSample record : mapRecord.values()) {
            System.debug('record: '+record);
            
            Sample_Received_Stage__c Obj = new Sample_Received_Stage__c();
                Obj.Product__c = record.Project;
                Obj.Quantity__c = record.Quantity;
                Obj.Recivied_Date__c = record.Recivied_Date;
                Obj.Collaboration_Key__c = record.CollaboratorKey;
                Opportunity Op = new Opportunity(Collaborator_Key__c = record.CollaboratorKey);
                Obj.Collaboration_Opportunity__r = op;
                Obj.Key__c = record.key;
            
            keySet.add(record.key);
            Samplerecord.add(Obj);
            
        }
        System.debug('Samplerecord: '+Samplerecord.Size());
        System.debug('jsonDT : '+jsonDT);
        System.debug('Samplerecord: '+Samplerecord);
        paginationData objDT =  new paginationData(); 
        if(isValidData){
            //upsert Samplerecord Key__c;
            System.debug('Inside upsert: '+Samplerecord);
            database.insert(Samplerecord, false);
            
            system.debug('keySet :'+keySet);
            

            List<Sample_Received_Stage__c> lstData = [SELECT Id, Product__c, Quantity__c, Key__c, Collaboration_Key__c, Recivied_Date__c 
                                                      FROM Sample_Received_Stage__c
                                                      WHERE Key__c IN: keySet];
            
             
        	objDT.smplerecivedlst = lstData;
            objDT.keySet = keySet;
            jsonDT = JSON.serialize(objDT);
            
            system.debug('jsonDT :'+jsonDT);
            
            system.debug('Samplerecord Key__c: '+Samplerecord[0].Key__c);
        }
        system.debug('isValidData: '+isValidData);
        List<Sample_Received_Stage__c> blankList =New List<Sample_Received_Stage__c>();
        
        jsonDT = isValidData ? jsonDT : '';
        
        objDT.jsonDT = jsonDT;
        
        return objDT;
    }
    @AuraEnabled 
    public static paginationData loadDataSample(Id contentDocumentId) {
        System.debug('contentDocumentId: '+contentDocumentId);
        String strMessage;
        string Records = '';
        if ( contentDocumentId != null ) {
            ContentVersion contentVersionObj = [ SELECT Id, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =:contentDocumentId ];
            strMessage = contentVersionObj.VersionData.toString();
        }
         paginationData objDT = new paginationData();
        try {
            
            objDT =  sampleReciviedProcessingRecord(strMessage);
            Records =  objDT.jsonDT;
            system.debug('Records :'+Records);
        }
        catch ( Exception e ) {
            strMessage = 'Some error occured. Please reach out to your System Admin';
            system.debug( e.getMessage() );
            system.debug( e);
        } 
        System.debug('Returned Value: '+Records);
        return objDT;
    }
    
    @AuraEnabled
    public static string updateSample(Object data) {
        System.debug('>>>'+data);
        List<Sample_Received_Stage__c> contactsForUpdate = (List<Sample_Received_Stage__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Sample_Received_Stage__c>.class
        );
        try {
            update contactsForUpdate ;
            return 'Success: Batch updated successfully';
        }
        catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }
    }
   
    public class wrapperSample{
        public String Project   {get;set;}
        public Integer Quantity  {get;set;}
        public Date Recivied_Date {get;set;}
        public string key {get;set;}
        public string CollaboratorKey {get;set;}
        public boolean showError {get;set;}
 	
    }
    
    @AuraEnabled
    public static string getLatestData(list<String> keySet) {
        
        system.debug('keySet :'+keySet);
        List<Sample_Received_Stage__c> lstData = [SELECT Id, Product__c, Quantity__c, Key__c, Collaboration_Key__c, Recivied_Date__c 
                                                      FROM Sample_Received_Stage__c
                                                      WHERE Key__c IN: keySet];
        
        	system.debug('lstData :'+lstData);
            String jsonDT = JSON.serialize(lstData);
            system.debug('jsonDT :'+jsonDT);
        
        return jsonDT;
    }
    public class paginationData{
        @AuraEnabled
        public List<Sample_Received_Stage__c> smplerecivedlst {get;set;}
        @AuraEnabled
        public Set<String> keySet {get;set;}
        @AuraEnabled
        public String jsonDT {get;set;}
        
    }
}