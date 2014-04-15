// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionDonatedItemConverter {
    /******C&P Code Start***********/
    public boolean paaspackage{get;set;}//Check PaaS Existance
    /******C&P Code End***********/
    // constructor
    public AUC_CTRL_AuctionDonatedItemConverter() {
        auctionMaintenance = new AUC_AuctionMaintenance();
        String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));       
        if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
            auctionMaintenance.auctionId = strAuctionId;
            if (listNewAuctionItem.size() == 0) strConvertResult = 'There are no more available Donated Items that need an Auction Item.';          
        } else {
            strConvertResult = 'There was no AuctionId passed as a parameter to the page.';
        }
        /************C&P Code Start***************/
        /*************Check if paas Package exists or not*************/
           paaspackage = false;
           List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
           if(!cls.isempty() && cls!= null){
              paaspackage= true;
           }
        /************C&P Code End***************/
    }

    private AUC_AuctionMaintenance auctionMaintenance;
    
    public string strConvertResult { get; set; }
    
    // wrapper class to hold an AuctionItem, Donated Item Opportunity, and a checkbox
    public class NewAuctionItem {   

        public Auction_Item__c ai { get; set; }
        public Opportunity donatedItem { get; set; }
        public boolean isChecked { get; set; }
        public integer quantity { get; set; }
        public decimal FMV { get; set; }
        
      
        public NewAuctionItem(Auction_Item__c aiT, Opportunity donatedItemT) {
            ai = aiT;
            donatedItem = donatedItemT;
            isChecked = true;
            quantity = integer.valueOf(donatedItemT.Number_Available__c);
            if (donatedItemT.Amount == null || donatedItemT.Number_of_Items__c == null) {
                FMV = 0;
            } else { 
            FMV = (donatedItemT.Amount / donatedItemT.Number_of_Items__c) * quantity;
            }
        }
    }
    
    // the list of new auction items that the visualforce page displays for editing
    public list<NewAuctionItem> listNewAuctionItem { 
        get {
            if (listNewAuctionItem == null) {
                listNewAuctionItem = new list<NewAuctionItem>();
                
                list<Opportunity> listOpp = [select Id, Name, Amount, Number_of_Items__c, Number_Available__c, 
                    Auction_Donated_Item_Name__c, Description, Auction_Donated_Item_Restrictions__c from Opportunity
                    where CampaignId = :auctionMaintenance.campaignIdAuctionDonors and 
                        RecordTypeId = :AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem and
                        Number_Available__c > 0 
                    order by Auction_Donated_Item_Name__c
                    limit :AUC_AuctionConstants.cDonatedItemConverterBatchSize];
                    
                // cache set of already used auction item id's
                list<Auction_Item__c> listAI = [select Name from Auction_Item__c where Auction__c = :auctionMaintenance.auctionId];
                set<string> setItemId = new set<string>();
                for (Auction_Item__c ai : listAI) {
                    setItemId.add(ai.Name);
                }               
                integer itemId = 100;
                
                for (Opportunity opp : listOpp) {
                    Auction_Item__c ai = new Auction_Item__c();
                    ai.Auction__c = auctionMaintenance.auctionId;
                    ai.Auction_Item_Name__c = opp.Auction_Donated_Item_Name__c;  
                    ai.Description__c = opp.Description;
                    ai.Restrictions__c = opp.Auction_Donated_Item_Restrictions__c;
                    
                    // generate a free auction item id
                    while (setItemId.contains(string.valueOf(itemId))) itemId++; 
                    ai.Name = string.valueOf(itemId++);                 
                    
                    listNewAuctionItem.add(new NewAuctionItem(ai, opp));                
                }
            }
            return listNewAuctionItem;
        }
        set;
    }               
    
    // list of all fieldnames for Auction Items.
    private list<string> listStrAIFields {
        get {
            if (listStrAIFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Auction_Item__c.fields.getMap();
                listStrAIFields = new list<string>();
                listStrAIFields.addAll(mapS.keySet());  
            }
            return listStrAIFields;
        }
        set;
    }
    
    // so we can throw an exception with an error message   
    private class MyException extends Exception {}
    
    // action method to create the auction items            
    public PageReference Convert() {
        list<Auction_Item__c> listAI = new list<Auction_Item__c>();
        list<Auction_Item_Piece__c> listAIP = new list<Auction_Item_Piece__c>();

        Savepoint sp = Database.setSavepoint();
        try {       
            // first create the Auction Item's
            for (NewAuctionItem nai : listNewAuctionItem) {
                if (nai.isChecked) {
                    // in order to handle the insert of AI's succeeding, but 
                    // then a later operation causing us to rollback,
                    // we have to clone the AI's so their ID won't get set
                    // by the insert!
                    Auction_Item__c ai = new Auction_Item__c();
                    AUC_AuctionMaintenance.CloneObject(nai.ai, ai, listStrAIFields);
                    listAI.add(ai);
                }
            }
            insert listAI;
            
            // now create the Auction Item Pieces
            integer iAI = 0;
            for (NewAuctionItem nai : listNewAuctionItem) {
                if (nai.isChecked) {
                    Auction_Item_Piece__c aip = new Auction_Item_Piece__c();
                    aip.Auction_Item__c = listAI[iAI++].Id;
                    aip.Opportunity__c = nai.donatedItem.Id;
                    if (nai.quantity == null || nai.quantity <= 0) {
                        throw (new MyException(nai.ai.Auction_Item_Name__c + ': Quantity cannot be less than one.'));                                               
                    }
                    if (nai.quantity > nai.donatedItem.Number_Available__c) {
                        throw (new MyException(nai.ai.Auction_Item_Name__c + 
                            ': Quantity cannot be more than the number available (' + nai.donatedItem.Number_Available__c + ').'));                     
                    }
                    aip.Quantity__c = nai.quantity;
                    aip.Actual_FMV__c = (nai.donatedItem.Amount / nai.donatedItem.Number_Of_Items__c) * aip.Quantity__c;
                    listAIP.add(aip);
                }
            }
            insert listAIP;
            
            strConvertResult = listAIP.size() + ' Auction Items were created.  The list has been refreshed to show remaining Donated Items.';
            listNewAuctionItem = null;
        } catch (Exception e) {
            // undo our partially saved state
            Database.rollback(sp);                      
            strConvertResult = 'Errors occurred: ';
            ApexPages.addMessages(e);            
        }

        return null;
    }

    // cancel the page and return to our caller. 
    public PageReference Cancel() {
        string retURL = ApexPages.currentPage().getParameters().get('retURL');
        if (retURL == null || retURL == '') {
            retURL = '/apex/GW_Auctions__AuctionItems';
        }
        PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
        
    }
}