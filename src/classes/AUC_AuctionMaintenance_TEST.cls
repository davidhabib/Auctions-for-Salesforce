// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_AuctionMaintenance_TEST {

	static testMethod void CodeCoverageTests() {
		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today(),
			Ticket_Non_Deductible_Amount__c = 25
		);
		insert auction;

		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;

		System.assert(AUC_AuctionMaintenance.recordtypeIdAuctionCampaign != null);
		System.assert(AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem != null);
		System.assert(AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem != null);
		System.assert(AUC_AuctionMaintenance.recordtypeIdAuctionTicket != null);
		System.assert(AUC_AuctionMaintenance.recordtypeIdAuctionGift != null);
		System.assertEquals(System.today().year(), AUC_AuctionMaintenance.YearOfAuctionId(auction.Id));
		System.assertEquals(System.today(), AUC_AuctionMaintenance.DateOfAuctionId(auction.Id));
		System.assertEquals('Test Auction', AUC_AuctionMaintenance.NameOfAuctionId(auction.Id));

		System.assertEquals(null, AUC_AuctionMaintenance.StrEscape(null));
		System.assertEquals('', AUC_AuctionMaintenance.StrEscape(''));
		System.assertEquals('foo', AUC_AuctionMaintenance.StrEscape('foo'));
		System.assertEquals('\\\'', AUC_AuctionMaintenance.StrEscape('\''));

		System.assertNotEquals(null, AUC_AuctionMaintenance.listStrFromFieldSet('Contact',
			UTIL_Describe.StrTokenNSPrefix('AuctionsCheckInFS')));
		System.assertNotEquals(null, AUC_AuctionMaintenance.setFieldNamesFromFieldSet('Contact',
			UTIL_Describe.StrTokenNSPrefix('AuctionsCheckInFS')));
		System.assertNotEquals(null, AUC_AuctionMaintenance.strFieldNamesFromFieldSet('Contact',
			UTIL_Describe.StrTokenNSPrefix('AuctionsCheckInFS')));

		List<SelectOption> ListSO = am.listSOAuctions;
		System.assert(ListSO.size() > 1);

		System.assert(am.campaignIdAuctionAttendees != null);
		System.assert(am.campaignIdAuctionDonors != null);
		System.assert(am.campaignIdAuctionTickets != null);
		System.assertEquals(25, AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auction.Id));

		// test out that if NPSP is installed, we can update the special fields for the Opp's OCR.
		Opportunity opp = new Opportunity();
		Contact con = new Contact(LastName='test');
		insert con;
		System.assertNotEquals(null, con.Id);
		System.assertEquals(AUC_AuctionConstants.IsNPSPInstalled, AUC_AuctionMaintenance.didUpdateOppWithNPSPOCRData(opp, con.Id));
	}

	static testMethod void testNewContactRoles() {
		Account acc = new Account(Name='test account');
		insert acc;
		Contact con = new Contact(LastName='test contact');
		insert con;

		List<Opportunity> ListOpp = new List<Opportunity>();
		List<OpportunityContactRole> ListOCR = new List<OpportunityContactRole>();
		for (Integer i = 0; i < 5; i++) {
			ListOpp.add(new Opportunity(Name='test Opp'+i, StageName='Closed Won', CloseDate=System.today()));
			ListOCR.add(new OpportunityContactRole(ContactId=con.Id, IsPrimary=true, Role='test Role'));
		}
		insert ListOpp;
		for (Integer i = 0; i < ListOpp.size(); i++) {
			ListOCR[i].OpportunityId = ListOpp[i].Id;
		}

		Test.startTest();
		AUC_AuctionMaintenance.saveOppContactRoles(ListOCR);
		Test.stopTest();

		List<OpportunityContactRole> ListOCRSaved = [SELECT Id, ContactId, OpportunityId, IsPrimary, Role
		FROM OpportunityContactRole ORDER BY Opportunity.Name];
		System.assertEquals(ListOCR.size(), ListOCRSaved.size());
		for (Integer i = 0; i < ListOCR.size(); i++) {
			System.assertEquals(ListOCR[i].OpportunityId, ListOCRSaved[i].OpportunityId);
			System.assertEquals(ListOCR[i].ContactId, ListOCRSaved[i].ContactId);
			System.assertEquals(ListOCR[i].IsPrimary, ListOCRSaved[i].IsPrimary);
			System.assertEquals(ListOCR[i].Role, ListOCRSaved[i].Role);
		}
	}

	static testMethod void testExistingContactRoles() {
		Account acc = new Account(Name='test account');
		insert acc;
		Contact con = new Contact(LastName='test contact');
		insert con;

		List<Opportunity> ListOpp = new List<Opportunity>();
		List<OpportunityContactRole> ListOCR = new List<OpportunityContactRole>();
		for (Integer i = 0; i < 5; i++) {
			ListOpp.add(new Opportunity(Name='test Opp'+i, StageName='Closed Won', CloseDate=System.today()));
			ListOCR.add(new OpportunityContactRole(ContactId=con.Id, IsPrimary=true, Role='test Role'));
		}
		insert ListOpp;
		for (Integer i = 0; i < ListOpp.size(); i++) {
			ListOCR[i].OpportunityId = ListOpp[i].Id;
		}
		insert ListOCR;

		// now change our Roles and use our method to update them.
		for (Integer i = 0; i < ListOCR.size(); i++) {
			ListOCR[i].Role = 'new test Role';
		}

		Test.startTest();
		AUC_AuctionMaintenance.saveOppContactRoles(ListOCR);
		Test.stopTest();

		List<OpportunityContactRole> ListOCRSaved = [SELECT Id, ContactId, OpportunityId, IsPrimary, Role
		FROM OpportunityContactRole ORDER BY Opportunity.Name];
		System.assertEquals(ListOCR.size(), ListOCRSaved.size());
		for (Integer i = 0; i < ListOCR.size(); i++) {
			System.assertEquals(ListOCR[i].OpportunityId, ListOCRSaved[i].OpportunityId);
			System.assertEquals(ListOCR[i].ContactId, ListOCRSaved[i].ContactId);
			System.assertEquals(ListOCR[i].IsPrimary, ListOCRSaved[i].IsPrimary);
			System.assertEquals(ListOCR[i].Role, ListOCRSaved[i].Role);
			System.assertEquals('new test Role', ListOCRSaved[i].Role);
		}
	}

	static testMethod void testCloneObject() {
		Contact con1 = new Contact(LastName='Foo');
		Contact con2 = new Contact();
		AUC_AuctionMaintenance.CloneObject(con1, con2, new List<String>{'FirstName', 'LastName'});
		System.assertEquals(con1.LastName, con2.LastName);
	}

	static testMethod void testUpdateNPSPPayments() {
		Account acc = new Account(Name='test account');
		insert acc;
		Contact con = new Contact(LastName='test contact');
		insert con;

		List<Opportunity> ListOpp = new List<Opportunity>();
		for (Integer i = 0; i < 5; i++) {
			ListOpp.add(new Opportunity(Name='test Opp'+i, StageName='Closed Won', CloseDate=System.today()));
		}
		insert ListOpp;

		AUC_AuctionMaintenance.UpdateNPSPPayments(ListOpp, 'Check', '1234');
		if (AUC_AuctionConstants.IsNPSPInstalled) {
			List<SObject> listPayments = new List<SObject>();
			String strSoql = 'SELECT Id, npe01__Payment_Method__c, npe01__Check_Reference_Number__c  ' +
				' FROM npe01__OppPayment__c WHERE npe01__Opportunity__c IN :listOpp ';
			listPayments = Database.query(strSoql);
			for (SObject pmt : listPayments) {
				System.assertEquals('Check', String.valueOf(pmt.get('npe01__Payment_Method__c')));
				System.assertEquals('1234', String.valueOf(pmt.get('npe01__Check_Reference_Number__c')));
			}
		}
	}

	static testMethod void testStrPaymentMethodOrCheckFromNPSPPayments() {
		Opportunity opp = new Opportunity(Name='test Opp', StageName='Closed Won', CloseDate=System.today());
		insert opp;
		System.assertEquals(null, AUC_AuctionMaintenance.strPaymentMethodOrCheckFromNPSPPayments(opp.Id, false));
	}

	static testMethod void testSetOpportunityStageClosed() {
		Opportunity opp = new Opportunity();
		AUC_AuctionMaintenance.setOpportunityStageClosed(opp);
		System.assertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, opp.StageName);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedProbability, opp.Probability);
		System.assertEquals(AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName, opp.ForecastCategoryName);
	}

	static testMethod void testStrOppTicketName() {
		Auction__c auction = new Auction__c (
			Name = 'Bingo',
			Auction_Date__c = System.today(),
			Ticket_Non_Deductible_Amount__c = 25
		);
		insert auction;
		Contact con = new Contact(FirstName='Joe', LastName='Blow');
		insert con;
		Account acc = new Account(Name='Acme');
		insert acc;

		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;

		System.assertEquals('Joe Blow Bingo Auction Ticket', am.StrOppTicketName(null, con.Id));
		System.assertEquals('Acme Bingo Auction Ticket', am.StrOppTicketName(acc.Id, null));
	}

}