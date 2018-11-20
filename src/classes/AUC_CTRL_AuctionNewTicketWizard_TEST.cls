// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionNewTicketWizard_TEST {

	public static testMethod void CodeCoverageTests() {
		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;
		System.assert(auction.Id != null);

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets
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

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionNewTicketWizard');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewTicketWizard ctrl = new AUC_CTRL_AuctionNewTicketWizard();
		ctrl.contactRole.ContactId = contact.Id;
		System.assertEquals(campaign.Id, ctrl.opp.CampaignId);
		System.assertEquals(System.today(), ctrl.opp.CloseDate);
		System.assertNotEquals(null, ctrl.listSOStatuses);
		ctrl.opp.Amount = 15;
		ctrl.opp.Number_of_Tickets__c = 4;
		ctrl.OnChange_NumberOfTickets();
		System.assertEquals(4, ctrl.listCmpMbrAttendees.size());
		System.assertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
		ctrl.ChangePaymentMethod();
		ctrl.ShowPanelCreditCard();
		System.assertEquals(true, ctrl.fShowPanelCreditCard);
		System.assertEquals('Credit Card', ctrl.strPaymentMethod);
		System.assertEquals(null, ctrl.strCheckNumber);
		System.assertEquals(null, ctrl.strCreditCardChargeURL);
		System.assertNotEquals(null, ctrl.strPaymentProcessorWindowParameters);
		System.assertEquals(false, ctrl.fShowPaymentProcessorOnPage);
		System.assertNotEquals(null, ctrl.strPaymentProcessorPageHeight);
		System.assertEquals(ctrl.isPaymentSettingsMissing, ctrl.isPaymentSettingsMissing);

		ctrl.Save();
		System.assert(ctrl.opp.Id != null);
		System.assertEquals('The ticket purchase has been saved.  1 contacts have been added to the auction attendee campaign.', ctrl.strSaveResults);
		List<Opportunity> listOpp = [SELECT Id, Name, Amount, StageName, Probability, ForecastCategoryName FROM Opportunity];
		System.assertEquals(1, listOpp.size());
		System.assertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, listOpp[0].StageName);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedProbability, listOpp[0].Probability);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName, listOpp[0].ForecastCategoryName);
		List<OpportunityContactRole> listOCR = [SELECT Id, ContactId FROM OpportunityContactRole WHERE IsPrimary=TRUE];
		System.assertEquals(1,listOCR.size());
		System.assertEquals(contact.Id, listOCR[0].ContactId);

		// now test editing an existing ticket opp
		//point to our VF page
		p = new PageReference('Page.AuctionNewTicketWizard');
		p.getParameters().put('auctionId', auction.Id);
		p.getParameters().put('oppId', ctrl.opp.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		ctrl = new AUC_CTRL_AuctionNewTicketWizard();
		System.assertEquals(contact.Id, ctrl.contactRole.ContactId);
		System.assertEquals(campaign.Id, ctrl.opp.CampaignId);
		System.assertEquals(System.today(), ctrl.opp.CloseDate);
		ctrl.opp.Amount = 25;
		ctrl.opp.Number_of_Tickets__c = 6;
		ctrl.OnChange_NumberOfTickets();
		System.assertEquals(6, ctrl.listCmpMbrAttendees.size());
		System.assertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
		ctrl.Save();
		System.assertEquals('The ticket purchase has been saved.  0 contacts have been added to the auction attendee campaign.  1 contacts have been updated in the auction attendee campaign.', ctrl.strSaveResults);
		System.assertNotEquals(null, ctrl.SaveAndClose());
		System.assertNotEquals(null, ctrl.Cancel());


		// test deleting the CampaignMember
		ctrl.idDeleteCM = ctrl.listCmpMbrAttendees[0].Id;
		System.assertEquals(null, ctrl.DeleteCM());
	}

	static testMethod void UnitTestNullAuction() {
		// delete all auctions first
		delete [SELECT Id FROM Auction__c];

		//point to our VF page
		PageReference page = new PageReference('Page.AuctionNewTicketWizard');
		page.getParameters().put('auctionId', 'null');
		Test.setCurrentPageReference(page);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewTicketWizard ctrl = new AUC_CTRL_AuctionNewTicketWizard();
		System.assertEquals(null, ctrl.auctionId);
		System.assertEquals(1, ctrl.listSOAuctions.size());
		System.assertEquals(0, ctrl.listCmpMbrAttendees.size());
		ctrl.Cancel();
	}
}