// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionNewDonatedItemWizard_TST {


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

		Auction_Item__c auctionitem = new Auction_Item__c (
			Auction_Item_Name__c = 'Test Auction item',
			Auction__c = auction.Id
		);
		insert auctionitem;

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


		//point to our VF page
		PageReference p = new PageReference('Page.AuctionNewDonatedItemWizard');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewDonatedItemWizard ctrl = new AUC_CTRL_AuctionNewDonatedItemWizard();

		ctrl.contactRole.ContactId = contact.Id;
		ctrl.opp.AccountId = acc.Id;
		ctrl.opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;
		ctrl.opp.CloseDate = System.today();
		ctrl.opp.Auction_Donated_Item_Name__c = 'my test auction donated item';
		ctrl.opp.Amount = 150;
		ctrl.opp.Number_of_Items__c = 1;
		ctrl.opp.Description = 'my description of the donated item';
		ctrl.opp.Auction_Donated_Item_Restrictions__c = 'you are restricted!';

		ctrl.fCreateAuctionItem = true;
		System.assertEquals('true', ctrl.StrFCreateAuctionItem);
		ctrl.ToggleCreateAuctionItem();
		System.assertEquals(ctrl.fCreateAuctionItem, true);
		System.assertEquals(ctrl.auctionItem.Auction__c, auction.Id);
		System.assertEquals(ctrl.auctionItem.Auction_Item_Name__c, ctrl.opp.Auction_Donated_Item_Name__c);
		System.assertEquals(ctrl.auctionItem.Description__c, ctrl.opp.Description);
		System.assertEquals(ctrl.auctionItem.Restrictions__c, ctrl.opp.Auction_Donated_Item_Restrictions__c);

		ctrl.auctionItem.Auction_Item_Name__c = 'my test auction item';

		ctrl.Save();

		List<Opportunity> listOpp = [SELECT Id, Name, Amount, StageName, Probability, ForecastCategoryName FROM Opportunity];
		System.assertEquals(1, listOpp.size());
		System.assertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, listOpp[0].StageName);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedProbability, listOpp[0].Probability);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName, listOpp[0].ForecastCategoryName);
		List<OpportunityContactRole> listOCR = [SELECT Id, ContactId FROM OpportunityContactRole WHERE IsPrimary=TRUE];
		System.assertEquals(1,listOCR.size());
		System.assertEquals(contact.Id, listOCR[0].ContactId);

		ctrl.Cancel();

		// verify the auctionItem got correctly created!
		List<Auction_Item__c> listAI = [SELECT Id, Auction_Item_Name__c FROM Auction_Item__c WHERE Id=:ctrl.auctionItem.Id];
		System.assertEquals('my test auction item', listAI[0].Auction_Item_Name__c);
	}
}