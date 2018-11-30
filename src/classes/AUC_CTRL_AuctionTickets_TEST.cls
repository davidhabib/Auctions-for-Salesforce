// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionTickets_TEST {

	static testMethod void CodeCoverageTests() {
		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign
		WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets
		AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		Opportunity oppDonatedItem = new Opportunity (
			Name = 'Test Opportunity',
			Auction_Donated_Item_Name__c = 'Test Auction Ticket',
			Amount = 50,
			CampaignId = campaign.Id,
			RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
			StageName = 'Won Not Thanked',
			CloseDate = System.today()
		);
		insert oppDonatedItem;

		am.auctionId = auction.Id;
		System.assertEquals(campaign.Id, am.campaignIdAuctionTickets);

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionTickets');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller
		AUC_CTRL_AuctionTickets pageCtrl = new AUC_CTRL_AuctionTickets();
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		compCtrl.pgController = pageCtrl;
		System.assert(pageCtrl.listStrFields != null);
		System.assert(pageCtrl.strNameField != null);
		pageCtrl.ctrlSoqlListView.strAlphaFilter = 'A';
		System.assert(pageCtrl.getStrSoql() != null);
		System.assert(pageCtrl.NewItem() != null);
		System.assert(pageCtrl.AutoAssignBidNumbers() != null);
		System.assertNotEquals(null, pageCtrl.AuctionCheckIn());
		System.assertNotEquals(null, pageCtrl.EditItem(null));
	}
}