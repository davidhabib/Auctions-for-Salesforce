// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionDonatedItems extends PageControllerBase {

	// constructor
	public AUC_CTRL_AuctionDonatedItems() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity',
	        UTIL_Describe.StrTokenNSPrefix('AuctionDonatedItemsTabFS'));
       	strNameField = listStrFields[0]; 
       	strObjectType = 'Opportunity'; 	
	} 
	
	public override String getStrPageUniqueName() {
		return 'DonatedItems';
	}
	
	public override String getStrSoql() {
		String strSoql = 'SELECT Id, ' + String.join(listStrFields, ',') +
				' FROM Opportunity ' +
        		' WHERE RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem  +
        		'\' AND CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionDonors + '\'';
        		
		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' AND ' +
				UTIL_Describe.StrTokenNSPrefix('Auction_Donated_Item_Name__c') +
				' LIKE \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        		
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		PageReference p = Page.AuctionNewDonatedItemWizard;
		p.getParameters().put('auctionId', ctrlSoqlListView.auctionId);
		return p;		
	}
	
	public PageReference DonatedItemConverter() {
		PageReference p = Page.AuctionDonatedItemConverter;
		p.getParameters().put('auctionId', ctrlSoqlListView.auctionId);
		p.getParameters().put('retURL', Page.AuctionDonatedItems.getUrl());
		return p;
	}
}