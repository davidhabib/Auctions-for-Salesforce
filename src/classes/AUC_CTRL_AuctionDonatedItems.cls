// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionDonatedItems extends PageControllerBase {

    // constructor
    public AUC_CTRL_AuctionDonatedItems() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'AuctionDonatedItemsTabFS');
        strNameField = listStrFields[0]; 
        strObjectType = 'Opportunity';  
    } 
    
    public override string getStrPageUniqueName() {
        return 'DonatedItems';
    }
    
    public override string getStrSoql() {       
        string strSoql = 'select Id, ' + string.join(listStrFields, ',') + 
                ' from opportunity ' + 
                ' where RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem  + 
                '\' and CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionDonors + '\'';
                
        if (ctrlSoqlListView.strAlphaFilter != null) {
            strSoql += ' and Auction_Donated_Item_Name__c like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
        }               
        return strSoql;         
    }

    public override PageReference NewItem() { 
        PageReference p = new PageReference('/apex/AuctionNewDonatedItemWizard?auctionId=' + ctrlSoqlListView.auctionId);
        return p;       
    }
    
    public PageReference DonatedItemConverter() {
        PageReference p = new PageReference('/apex/AuctionDonatedItemConverter?auctionId=' + 
            ctrlSoqlListView.auctionId +
            '&retURL=' +
            ApexPages.currentPage().getUrl());
        return p;
    }
}