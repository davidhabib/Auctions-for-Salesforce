// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionCheckOut_TEST {

	static testMethod void CodeCoverageTests() {
		// create needed data
		Account acc = new Account(Name='My Test Account');
		insert acc;
		Contact contact1 = new Contact(FirstName='David', LastName='Test', AccountId=acc.Id);
		insert contact1;
		Contact contact2 = new Contact(FirstName='John', LastName='Test', AccountId=acc.Id);
		insert contact2;

		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		CampaignMember cm1 = new CampaignMember();
		cm1.CampaignId = campaign.Id;
		cm1.ContactId = contact1.Id;
		insert cm1;

		CampaignMember cm2 = new CampaignMember();
		cm2.CampaignId = campaign.Id;
		cm2.ContactId = contact2.Id;
		insert cm2;

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
			StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED,
			CloseDate = System.today(),
			Amount = 150,
			Auction_Item_Purchased__c = ai.Id,
			Auction_Non_Deductible_Amount__c = 100
		);
		insert oppPurchase;
		System.assertEquals(150, oppPurchase.Amount);
		System.assertEquals(100, oppPurchase.Auction_Non_Deductible_Amount__c);

		Opportunity opp = [SELECT Id, Name, Auction_Deductible_Amount__c FROM Opportunity WHERE Id=:oppPurchase.Id];
		System.assertEquals(50, opp.Auction_Deductible_Amount__c);

		OpportunityContactRole oppcr = new OpportunityContactRole();
		oppcr.ContactId = contact1.Id;
		oppcr.OpportunityId = oppPurchase.Id;
		oppcr.IsPrimary = true;
		insert oppcr;

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionCheckOut');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionCheckOut ctrl = new AUC_CTRL_AuctionCheckOut();

		System.assertEquals(auction.Id, ctrl.auctionId);
		ctrl.ChangeAuction();
		System.assertEquals(auction.Id, ctrl.auctionId);

		ctrl.searchPurchaser = '';
		ctrl.SearchPurchaserLookup();
		System.assertEquals(null, ctrl.contactIdPurchaser);
		System.assert(ctrl.strStatus.startsWith('Enter the name'));

		ctrl.searchPurchaser = 'This guy does not exist';
		ctrl.SearchPurchaserLookup();
		System.assertEquals(null, ctrl.contactIdPurchaser);
		System.assert(ctrl.strStatus.startsWith('No attendee'));

		ctrl.searchPurchaser = 'David Test';
		ctrl.SearchPurchaserLookup();
		System.assertEquals(contact1.Id, ctrl.contactIdPurchaser);
		System.assertEquals('David Test - ', ctrl.strNamePurchaser);
		System.assert(ctrl.strStatus.startsWith('1. Check <b>Pay Now</b>'));
		System.assert(ctrl.listReceipts != null);
		System.assertEquals(1, ctrl.listReceipts.size());
		System.assert(ctrl.listReceipts[0].listOppAuctionPurchases != null);
		System.assertEquals(1, ctrl.listReceipts[0].listOppAuctionPurchases.size());
		System.assertEquals(150, ctrl.listReceipts[0].decTotalAmountToPay);
		System.assert(ctrl.strOpenReceiptURL != null);
		System.assert(ctrl.strCreditCardChargeURL == null || ctrl.strCreditCardChargeURL != null);
		System.assert(ctrl.fHasReceipts);

		ctrl.oppIdChecked = oppPurchase.Id;
		ctrl.listReceipts[0].listOppAuctionPurchases[0].IsPayNow = false;
		System.assertEquals(null, ctrl.ChangePayNow());
		System.assertEquals(0, ctrl.decTotalAmountToPay);
		System.assertEquals(null, ctrl.UpdateCheckedOpps());
		System.assertEquals('You must Check off which Opportunities to update.', ctrl.strSaveResults);

		ctrl.oppIdChecked = oppPurchase.Id;
		ctrl.listReceipts[0].listOppAuctionPurchases[0].IsPayNow = true;
		System.assertEquals(null, ctrl.ChangePayNow());
		System.assertEquals(150, ctrl.decTotalAmountToPay);
		List<Id> oppIdsToPay = ctrl.getOppIdsToPay();
		System.assertEquals(1, oppIdsToPay.size());
		System.assertEquals(oppPurchase.Id, oppIdsToPay[0]);

		opp = [SELECT Id, Name, Auction_Deductible_Amount__c, StageName FROM Opportunity WHERE Id=:oppPurchase.Id];
		System.assertEquals(AUC_AuctionConstants.OPP_STAGE_PLEDGED, opp.StageName);
		System.assert(ctrl.UpdateCheckedOpps() == null);
		opp = [SELECT Id, Name, Auction_Deductible_Amount__c, StageName, Probability, ForecastCategoryName FROM Opportunity WHERE Id=:oppPurchase.Id];
		System.assertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, opp.StageName);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedProbability, opp.Probability);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName, opp.ForecastCategoryName);

		List<AUC_CTRL_AuctionCheckOut.Purchaser> listP = AUC_CTRL_AuctionCheckOut.getListPurchasers(auction.Id, 'Test');
		System.assert(listP != null);
		System.assertEquals(2, listP.size());

		ctrl.contactIdPurchaser = contact2.Id;
		ctrl.ChangePurchaserLookup();
		System.assert(ctrl.strStatus.contains('no purchases'));
		System.assert(ctrl.listReceipts != null);
		System.assert(ctrl.listReceipts.size() == 0); // since contact2 has no purchases.
		System.assert(ctrl.fHasReceipts == false);
		System.assert(ctrl.Close() != null);

		System.assertEquals(null, ctrl.NextGuest());
		System.assertEquals(null, ctrl.ChangePaymentMethod());
		System.assertNotEquals(null, ctrl.strPaymentProcessorWindowParameters);
		System.assertNotEquals(null, ctrl.fShowPaymentProcessorOnPage);
		System.assertNotEquals(null, ctrl.strPaymentProcessorPageHeight);
		System.assertEquals(null, ctrl.ShowPanelCreditCard());
		System.assertEquals(true, ctrl.isPaymentSettingsMissing);


	}

	static testMethod void handleNoAuction() {
		//point to our VF page
		PageReference p = new PageReference('Page.AuctionCheckOut');
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionCheckOut ctrl = new AUC_CTRL_AuctionCheckOut();

		System.assertEquals(null, ctrl.auctionId);
		System.assertEquals('You must first create an Auction before using this page.', ctrl.strSaveResults);
		System.assertEquals(ctrl.strSaveResults, ctrl.strStatus);

	}
}