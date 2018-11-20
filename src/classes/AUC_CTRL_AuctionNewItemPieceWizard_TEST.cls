// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionNewItemPieceWizard_TEST {

	static testMethod void TestCodeCoverage() {

		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign
		WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors
		AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		Auction_Item__c auctionitem = new Auction_Item__c (
			Auction_Item_Name__c = 'Test Auction item',
			Auction__c = auction.Id
		);
		insert auctionitem;

		Opportunity oppDonatedItem = new Opportunity (
			Amount = 100,
			Auction_Donated_Item_Name__c = 'Test Donated Item',
			CampaignId = campaign.Id,
			Name = 'Test Donated Item Opportunity',
			Number_of_Items__c = 10,
			RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem,
			StageName = 'CLOSED WON',
			CloseDate = System.today()
		);
		insert oppDonatedItem;

		//point to our VF page
		Test.setCurrentPage(new PageReference('Page.AuctionNewItemPieceWizard'));

		// create the AIP and set it up
		Auction_Item_Piece__c aip = new Auction_Item_Piece__c();
		aip.Auction_Item__c = auctionitem.Id;
		aip.Opportunity__c = oppDonatedItem.Id;

		//pass AIP into the controller
		ApexPages.StandardController sc = new ApexPages.StandardController(aip);

		//pass the controller into the extension
		AUC_CTRL_AuctionNewItemPieceWizard ext = new AUC_CTRL_AuctionNewItemPieceWizard(sc);

		System.assertEquals(auction.Id, ext.auctionId);
		System.assertEquals(auctionitem.Id, ext.auctionItemId);
		System.assertEquals(oppDonatedItem.Id, ext.oppDonatedItemId);
		System.assertEquals(2, ext.listSOAuctionItems.size());	// 2 because of the empty entry
		System.assertEquals(2, ext.listSODonatedItems.size());  // 2 because of the empty entry
		ext.aip.Quantity__c = 1;
		ext.aip.Actual_FMV__c = 10;
		System.assertNotEquals(null, ext.Save());
		System.assertNotEquals(null, ext.SaveAndNew());
		System.assertNotEquals(null, ext.Cancel());

	}
}