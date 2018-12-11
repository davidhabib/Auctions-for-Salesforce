// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionItems extends PageControllerBase {

	// constructor
	public AUC_CTRL_AuctionItems() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet(
	        UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'),
	        UTIL_Describe.StrTokenNSPrefix('AuctionItemsTabFS'));
       	strNameField = listStrFields[0]; 
       	strObjectType = UTIL_Describe.StrTokenNSPrefix('Auction_Item__c');
	}

	public override String getStrPageUniqueName() {
		return 'AuctionItems';
	}	
	
	public override String getStrSoql() {
		String strSoql = 'SELECT Id, ' + String.join(listStrFields, ',') +
				' FROM ' + UTIL_Describe.StrTokenNSPrefix('Auction_Item__c') +
				' WHERE ' + UTIL_Describe.StrTokenNSPrefix('Auction__c') + ' =\'' + ctrlSoqlListView.auctionId + '\'';

		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' AND ' + UTIL_Describe.StrTokenNSPrefix('Auction_Item_Name__c') +
				' LIKE \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        						
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		// ideally, we'd pass the AuctionId to the new page, but I haven't 
		// figured out how to do that in a way that works with a managed package.
		String strPrefix = Schema.getGlobalDescribe().get(UTIL_Describe.StrTokenNSPrefix('Auction_Item__c')).getDescribe().getKeyPrefix();
		//String strAuctionFldId = 'CF00NA0000001MnD3';  NOTE: couldn't find a way to get this at runtime!
		//list<Auction__c> listAuc = [select Id, Name from Auction__c where Id = :ctrlSoqlListView.auctionId] ;

		PageReference p = new PageReference('/' + strPrefix + '/e?' + 
			// strAuctionFldId + '=' + (listAuc.size() > 0 ? listAuc[0].Name : '') + '&' + 
			// strAuctionFldId + '_lkid=' + ctrlSoqlListView.auctionId + 
			'&retURL=' + Page.AuctionItems.getUrl());
		return p;
	}
	
	public PageReference DonatedItemConverter() {
		PageReference p = Page.AuctionDonatedItemConverter;
		p.getParameters().put('auctionId', ctrlSoqlListView.auctionId);
		p.getParameters().put('retURL', Page.AuctionItems.getUrl());
		return p;
	}
}