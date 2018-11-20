// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionItems_TEST {

	static testMethod void CodeCoverageTests() {
		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Auction_Item__c ai = new Auction_Item__c(
			Auction__c = auction.Id,
			Auction_Item_Name__c = 'Test Auction Item'
		);
		insert ai;

		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionItems');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller
		AUC_CTRL_AuctionItems pageCtrl = new AUC_CTRL_AuctionItems();
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		compCtrl.pageController = pageCtrl;
		System.assert(pageCtrl.listStrFields != null);
		System.assert(pageCtrl.strNameField != null);
		pageCtrl.ctrlSoqlListView.strAlphaFilter = 'A';
		System.assert(pageCtrl.getStrSoql() != null);
		System.assert(pageCtrl.NewItem() != null);
		System.assertNotEquals(null, pageCtrl.DonatedItemConverter());
	}
}