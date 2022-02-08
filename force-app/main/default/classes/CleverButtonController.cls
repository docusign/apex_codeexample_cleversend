public class CleverButtonController {
    @AuraEnabled
    public static String sendEnvelope(String recordId, String template, String description){
        try {
            Id mySourceId = userInfo.getUserId(); // The ID of the initiating Salesforce object.
            //  Create an empty envelope
            dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(recordId));
  
            //	Get relevant contact from opp - insert logic yourself
            Contact myContact = [SELECT Id, Name, Email, MobilePhone, DOB_for_Access_Code__c FROM Contact WHERE Name LIKE 'Randy Orton' LIMIT 1];
  
            //	Create recipient from contact
            dfsle.Recipient myRecipient = dfsle.Recipient.fromSource(
            myContact.Name,
            myContact.Email,
            myContact.MobilePhone,
            'Signer 1',
            new dfsle.Entity(myContact.Id));
            
            //	myRecipient.withSmsDelivery(myContact.MobilePhone);		//	Include SMS

            // Adding access code based on Contact's DOB
            dfsle.Recipient.Authentication authentication = new dfsle.Recipient.Authentication(myContact.DOB_for_Access_Code__c, false, null);
            myRecipient.withAuthentication(authentication);
            System.debug('DOB Access Code: ' + myContact.DOB_for_Access_Code__c);

            //	Assign recipient to env
            myEnvelope = myEnvelope.withRecipients(new List<dfsle.Recipient> {myRecipient});
  
            List<dfsle.Document> envDocList = new List<dfsle.Document>();
            
            //	Get template
            dfsle.UUID myTemplateId = dfsle.UUID.parse(template);
  
            //	Set Document from Template
            dfsle.Document myDocument = dfsle.Document.fromTemplate(myTemplateId, 'applicationForm');
            envDocList.add(myDocument);
            
            //	Attached documents based on Custom object fields (country, region) - insert logic yourself
            List<string> supplementaryDocIDs = new List<String>();                         
            try {
                supplementaryDocIDs.add('0634W00000INPU2QBQ');
            }
            catch(Exception e){
                System.debug('Supp Doc error');
            }
            
             //	Add supplementary documents to envelope
            try {
                //  The ID of a document stored in a Salesforce library
                for(Integer i = 0; i < supplementaryDocIDs.size(); i++){
                    Id myFileId = [SELECT id from ContentVersion where ContentDocumentId = :supplementaryDocIDs[i] LIMIT 1].id;

                    List<dfsle.Document> docList = dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set <Id> {myFileId});
                    dfsle.Document suppDocument = docList.get(0);

                    suppDocument.withSupplementalOptions(new dfsle.Document.SupplementalOptions(
                        dfsle.Document.SIGNER_ACKNOWLEDGEMENT_VIEW_ACCEPT,      // Signer must view and accept this document
                        true));     // Include this document in the combined document download.
                        
                    envDocList.add(suppDocument);
                }
            
                //	Adding all documents into envelope
                myEnvelope = myEnvelope.withDocuments(envDocList);
            }
            catch(Exception e){
                System.debug('error');
            }
            
            //	Set SF ID to link envelope to SF object for tracking
            List<String> items;
            dfsle.CustomField sf_source_id = new dfsle.CustomField('text', 'dfsle__SourceId__c', recordId, items, true, false);
            myEnvelope = myEnvelope.withCustomFields(new List<dfsle.CustomField> {sf_source_id});
  
            //	Send envelope
            myEnvelope = dfsle.EnvelopeService.sendEnvelope(myEnvelope, true);

            // Return string value of DocuSign envelope ID
            return String.valueOf(myEnvelope.docuSignId);
          } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
  
    @AuraEnabled
    public static List<dfsle.Template> getDocuSignTemplates(){
        try {
            List<dfsle.Template> docuSignTemplates = dfsle.TemplateService.getTemplates();
            return docuSignTemplates;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
      }
  }