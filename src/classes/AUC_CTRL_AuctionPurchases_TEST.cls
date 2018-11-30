// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionPurchases_TEST {

	static testMethod void CodeCoverageTests() {
		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees
		AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		Auction_Item__c ai = new Auction_Item__c (
			Auction_Item_Name__c = 'Test Auction Item',
			Auction__c = auction.Id,
			FMV_Override__c = 100
		);
		insert ai;

		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;
		System.assertEquals(campaign.Id, am.campaignIdAuctionAttendees);

		Opportunity oppPurchase= new Opportunity (
			Name = 'My Auction Item Purchase',
			CampaignId = campaign.Id,
			RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
			StageName = 'Won Not Thanked',
			CloseDate = System.today(),
			Amount = 150
		);
		insert oppPurchase;

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionPurchases');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller
		AUC_CTRL_AuctionPurchases pageCtrl = new AUC_CTRL_AuctionPurchases();
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		compCtrl.pgController = pageCtrl;
		System.assert(pageCtrl.listStrFields != null);
		System.assert(pageCtrl.strNameField != null);
		pageCtrl.ctrlSoqlListView.strAlphaFilter = 'A';
		System.assert(pageCtrl.getStrSoql() != null);
		System.assert(pageCtrl.NewItem() != null);

	}
}