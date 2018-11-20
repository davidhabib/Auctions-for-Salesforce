// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionDonatedItems extends PageControllerBase {

	// constructor
	public AUC_CTRL_AuctionDonatedItems() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'GW_Auctions__AuctionDonatedItemsTabFS');
       	strNameField = listStrFields[0]; 
       	strObjectType = 'Opportunity'; 	
	} 
	
	public override String getStrPageUniqueName() {
		return 'DonatedItems';
	}
	
	public override String getStrSoql() {
		String strSoql = 'SELECT Id, ' + String.join(listStrFields, ',') +
				' FROM opportunity ' +
        		' WHERE RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem  +
        		'\' AND CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionDonors + '\'';
        		
		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' AND GW_Auctions__Auction_Donated_Item_Name__c LIKE \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        		
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		PageReference p = new PageReference('/apex/GW_Auctions__AuctionNewDonatedItemWizard?auctionId=' + ctrlSoqlListView.auctionId);
		return p;		
	}
	
	public PageReference DonatedItemConverter() {
		PageReference p = new PageReference('/apex/GW_Auctions__AuctionDonatedItemConverter?auctionId=' + 
			ctrlSoqlListView.auctionId +
			'&retURL=' +
			ApexPages.currentPage().getUrl());
		return p;
	}
}