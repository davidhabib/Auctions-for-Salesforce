// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionPurchases extends PageControllerBase {

    // constructor
    public AUC_CTRL_AuctionPurchases() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'AuctionPurchasesTabFS');
        strNameField = listStrFields[0]; 
        strObjectType = 'Opportunity';          
    }
    
    public override string getStrPageUniqueName() {
        return 'Purchases';
    }
        
    public override string getStrSoql() {   
        string strSoql = 'select Id, ' + string.join(listStrFields, ',') + 
                ' from opportunity ' +
                'where (RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem  + '\'' + 
                ' or RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionGift  + '\') ' +
                ' and CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionAttendees + '\'';
        
        if (ctrlSoqlListView.strAlphaFilter != null) {
            strSoql += ' and Name like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
        }               
        return strSoql;         
    }

    public override PageReference NewItem() { 
        PageReference p = new PageReference('/apex/AuctionNewPurchaseWizard?auctionId=' + ctrlSoqlListView.auctionId);
        return p;       
    }

}