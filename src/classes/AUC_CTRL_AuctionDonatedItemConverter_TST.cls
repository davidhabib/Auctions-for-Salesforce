// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionDonatedItemConverter_TST {

	static testMethod void CodeCoverageTests() {
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

		Account acc = new Account(Name='My Test Account');
		insert acc;

		Contact contact = new Contact(
			FirstName = 'Johnny',
			LastName = 'Test',
			AccountId = acc.Id
		);
		insert contact;

		CampaignMember campaignmember = new CampaignMember(
			CampaignId = campaign.Id,
			ContactId = contact.Id,
			Bid_Number__c = 123
		);
		insert campaignmember;

		Opportunity opp = new Opportunity(
			RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem,
			Name = 'my donated item opp',
			CampaignId = campaign.Id,
			StageName = 'Won Not Thanked',
			CloseDate = System.today(),
			Auction_Donated_Item_Name__c = 'my test auction donated item',
			Amount = 150,
			Number_of_Items__c = 5,
			Description = 'my description of the donated item'
		);
		insert opp;
		System.assert(opp.Id != null);

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionDonatedItemConverter');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionDonatedItemConverter ctrl = new AUC_CTRL_AuctionDonatedItemConverter();

		System.assertEquals(null, ctrl.strConvertResult);
		System.assert(ctrl.listNewAuctionItem != null);
		System.assertEquals(1, ctrl.listNewAuctionItem.size());
		ctrl.listNewAuctionItem[0].isChecked = true;

		// test error handling
		ctrl.listNewAuctionItem[0].quantity = null;
		System.assertEquals(null, ctrl.Convert());
		System.assert(ctrl.strConvertResult.contains('Errors occurred'));
		ctrl.listNewAuctionItem[0].quantity = 10;
		System.assertEquals(null, ctrl.Convert());
		System.assert(ctrl.strConvertResult.contains('Errors occurred'));

		// test successful convert
		ctrl.listNewAuctionItem[0].quantity = 1;
		System.assertEquals(null, ctrl.Convert());
		System.assert(ctrl.strConvertResult.contains('1 Auction Items were created.'));

		// verify the auctionItem got correctly created!
		List<Auction_Item__c> listAI = [SELECT Id, Auction_Item_Name__c FROM Auction_Item__c WHERE Auction__c = :auction.Id];
		System.assertEquals(1, listAI.size());
		System.assertEquals('my test auction donated item', listAI[0].Auction_Item_Name__c);

		// other methods
		System.assertNotEquals(null, ctrl.Cancel());
	}
}