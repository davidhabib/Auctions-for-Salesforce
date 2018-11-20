// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionNewPurchaseWizard_TEST {

	static testMethod void UnitTest() {

		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees
		AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		Auction_Item__c auctionitem = new Auction_Item__c (
			Auction_Item_Name__c = 'Test Auction item',
			Auction__c = auction.Id
		);
		insert auctionitem;
		auctionitem = [SELECT Id, Name, Auction_Item_Name__c FROM Auction_Item__c WHERE Id=:auctionitem.Id];
		String strAIName = auctionitem.Name;
		System.assert(strAIName != null);
		System.debug('Auction Item Id/Name is ' + strAIName);

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
			Status = 'RSVP Yes',
			Bid_Number__c = 123
		);
		insert campaignmember;
		System.assertEquals(1, [SELECT COUNT() from CampaignMember]);

		//point to our VF page
		Test.setCurrentPageReference(new PageReference('Page.NewAuctionPurchaseWizard'));

		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewPurchaseWizard controller = new AUC_CTRL_AuctionNewPurchaseWizard();

		List<SelectOption> listso = controller.listSOAuctions;
		System.assert(listso.size() > 0);

		// select the current auction
		controller.auctionId = auction.Id;
		controller.ChangeAuction();
		System.assertEquals(null, controller.strSaveResults);
		System.assertNotEquals(null, controller.campaignIdAuctionAttendees);
		System.assertEquals(2, controller.listSOLookupBidNumbers.size());
		System.assertEquals(null, controller.listSOLookupBidNumbers2);
		System.assertEquals(2, controller.listSOLookupAuctionItems.size());
		System.assertEquals(null, controller.listSOLookupAuctionItems2);
		System.assertEquals(campaign.Id, controller.campaignIdAuctionAttendees);

		List<AUC_PurchaseOpportunity> listAPO = controller.listAuctionPurchasedItems;
		listAPO[0].strBidderNumberAndName = '123: Johnny Test';
		listAPO[0].contactId = contact.Id;
		listAPO[0].strAuctionItemIDAndName = strAIName + ': ' + auctionitem.Auction_Item_Name__c;
		listAPO[0].opp.Auction_Item_Purchased__c = auctionitem.Id;
		listAPO[0].strAmount = '99';
		listAPO[0].IsPayNow = true;
		listAPO[0].opp.CloseDate = Date.valueOf('2049-12-31');
		System.assertEquals('Johnny Test', listAPO[0].strBidderName);
		System.assertEquals('Test Auction item', listAPO[0].strAuctionItemName);

		listAPO[1].strBidderNumberAndName = '123: Johnny Test';
		listAPO[1].contactId = contact.Id;
		listAPO[1].strAuctionItemIDAndName = strAIName + ': ' + auctionitem.Auction_Item_Name__c;
		listAPO[1].opp.Auction_Item_Purchased__c = auctionitem.Id;
		//listAPO[1].strAmount = '99';
		listAPO[1].IsPayNow = true;
		listAPO[1].opp.CloseDate = Date.valueOf('2049-12-31');

		// test failure on save
		controller.CreateAuctionPurchases();
		System.assertEquals('Error encountered while trying to save auction purchases.', controller.strSaveResults);

		// do the save and validate it works
		listAPO[1].strBidderNumberAndName = null;
		listAPO[1].strAuctionItemIdAndName = null;
		listAPO[1].contactId = null;
		listAPO[1].opp.Auction_Item_Purchased__c = null;
		controller.CreateAuctionPurchases();
		System.assertEquals('Successfully saved 1 auction purchase(s).', controller.strSaveResults);
		List<Opportunity> auctionpurchases = [SELECT Amount, Auction_Item_Name__c, StageName, Probability, ForecastCategoryName
			FROM Opportunity WHERE CloseDate=:Date.valueOf('2049-12-31')];
		System.assertEquals(1, auctionpurchases.size());
		System.assertEquals(99, auctionpurchases[0].Amount);
		System.assertEquals('Test Auction item', auctionpurchases[0].Auction_Item_Name__c);
		System.assertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, auctionpurchases[0].StageName);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedProbability, auctionpurchases[0].Probability);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName, auctionpurchases[0].ForecastCategoryName);

		List<OpportunityContactRole> listOCR = [SELECT Id, ContactId FROM OpportunityContactRole WHERE IsPrimary=TRUE];
		System.assertEquals(1, listOCR.size());
		System.assertEquals(contact.Id, listOCR[0].ContactId);

		controller.Cancel();

		// test handling no auction
		controller.auctionId = auction.Id;
		controller.ChangeAuction();
		System.assert(controller.listSOLookupBidNumbers.size() > 0);
		System.assert(controller.listSOLookupAuctionItems.size() > 0);
		System.assert(controller.campaignIdAuctionAttendees == campaign.Id);
	}

	static testMethod void UnitTestNullAuction() {
		// delete all auctions first
		delete [SELECT Id FROM Auction__c];

		//point to our VF page
		PageReference page = new PageReference('Page.NewAuctionPurchaseWizard');
		page.getParameters().put('auctionId', 'null');
		Test.setCurrentPageReference(page);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewPurchaseWizard ctrl = new AUC_CTRL_AuctionNewPurchaseWizard();
		System.assertEquals(null, ctrl.auctionId);
		System.assertEquals(null, ctrl.campaignIdAuctionAttendees);
		System.assertEquals(1, ctrl.listSOAuctions.size());
		ctrl.Cancel();
	}
}