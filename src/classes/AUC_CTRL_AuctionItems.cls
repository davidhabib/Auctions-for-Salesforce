// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionItems extends PageControllerBase {
    /*********C&P Code Start**********/
      public boolean paaspackage{get;set;}//Check PaaS existance 
      public  List<Auction_Item__c> Auc_Items = null; //To get Auctions Items fields
     /********C&P Code End*************/
    
    // constructor
    public AUC_CTRL_AuctionItems() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Auction_Item__c', 'AuctionItemsTabFS');
        strNameField = listStrFields[0]; 
        strObjectType = 'Auction_Item__c';    
        
        /************C&P Code Start***************/
        /*************Check if paas Package exists or not*************/
         paaspackage= false;
         List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
         if(!cls.isempty() && cls!= null){
             paaspackage= true;
         }
       /************C&P Code End***************/     
    }

    public override string getStrPageUniqueName() {
        return 'AuctionItems';
    }   
    
    public override string getStrSoql() {   
        string strSoql = 'select Id, ' + string.join(listStrFields, ',') + 
                ' from Auction_Item__c ' +
                'where Auction__c=\'' + ctrlSoqlListView.auctionId + '\''; 

        if (ctrlSoqlListView.strAlphaFilter != null) {
            strSoql += ' and Auction_Item_Name__c like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
        }                               
        return strSoql;         
    }

    public override PageReference NewItem() { 
        // ideally, we'd pass the AuctionId to the new page, but I haven't 
        // figured out how to do that in a way that works with a managed package.
        string strPrefix = Schema.getGlobalDescribe().get('Auction_Item__c').getDescribe().getKeyPrefix();
        //string strAuctionFldId = 'CF00NA0000001MnD3';  NOTE: couldn't find a way to get this at runtime!
        //list<Auction__c> listAuc = [select Id, Name from Auction__c where Id = :ctrlSoqlListView.auctionId] ;
//'/' + strPrefix + '/e?' + 
system.debug('ssssss'+strPrefix);
        PageReference p = new PageReference('/' + strPrefix + '/e?' + 
            // strAuctionFldId + '=' + (listAuc.size() > 0 ? listAuc[0].Name : '') + '&' + 
            // strAuctionFldId + '_lkid=' + ctrlSoqlListView.auctionId + 
            '&retURL=/apex/AuctionItems');
        return p;
    }
    
    public PageReference DonatedItemConverter() {
        PageReference p = new PageReference('/apex/AuctionDonatedItemConverter?auctionId=' + 
            ctrlSoqlListView.auctionId +
            '&retURL=' +
            ApexPages.currentPage().getUrl());
        return p;
    }
    /*******C&P Code Start********/
    //Navigating to AuctionItemsList page
    public ApexPages.PageReference downloadFile( ) { 
        return Page.AuctionItemsList; 
    }
    //to get fields from Auction Items object
    public List<Auction_Item__c> getAuc_Items(){
        if(Auc_Items == null){
            Auc_Items = [select Name, Allow_Multiple_Purchases__c, Auction__c, Auction_Group__c, Auction_Item_Name__c, SKU__c,Token_Value__c,Category__c,Description__c,Display_Board__c,Donor_Recognition__c,Fair_Market_Value__c,FMV_Override__c,FMV_Rollup__c,Guaranteed_Bid__c,Minimum_Bid__c,Restrictions__c,Show_Tax_Deductible__c,Total_Tax_Deductible__c,Treat_Purchase_as_Gift__c from Auction_Item__c where Auction__c=:ctrlSoqlListView.auctionId  limit 1000];
        }
        return Auc_Items;   
    }
    /*******C&P Code End********/
}