// Written by DavId Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionCheckIn_TEST {

	//==================== TEST METHOD(s) ======================================
	public static testMethod void CodeCoverageTests() {

		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;
		System.assert(auction.Id != null);

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign
			WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		Account acc = new Account(Name='My Test Account');
		insert acc;

		Contact contact = new Contact(
			FirstName = 'Johnny',
			LastName = 'Test',
			AccountId = acc.Id
		);
		insert contact;

		//instantiate the controller with no page parameters.
		AUC_CTRL_AuctionCheckIn ctrl = new AUC_CTRL_AuctionCheckIn();
		System.assert(ctrl != null);
		ctrl.SaveAttendeeInfo();
		System.assertEquals('Error encountered while trying to save.', ctrl.strSaveResults);
		System.assert(ctrl.strStatus != null);

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionCheckIn');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		ctrl = new AUC_CTRL_AuctionCheckIn();
		System.assertEquals(auction.Id, ctrl.auctionId);
		ctrl.ChangeAuction();
		System.assertEquals(auction.Id, ctrl.auctionId);
		System.assertEquals(auction.Id, ctrl.auctionMaintenance.auctionId);

		// test the initial state
		System.assertEquals(null, ctrl.contactIdAttendee);
		System.assertEquals(null, ctrl.IdCaptain);
		System.assertEquals(null, ctrl.strNameAttendee);
		System.assertEquals(null, ctrl.strNameCaptain);
		System.assertEquals(null, ctrl.searchAttendee);
		System.assertEquals(null, ctrl.strSaveResults);
		System.assertNotEquals(null, ctrl.strStatus);
		System.assert(ctrl.attendeeEdit != null);
		System.assert(ctrl.attendeeEdit.con != null);
		System.assert(ctrl.attendeeEdit.cm != null);
		System.assert(ctrl.oppTicketAttendee != null);
		System.assert(ctrl.listSOAuctions.size() > 0);
		System.assert(ctrl.listSOAuctions.size() > 0);
		System.assertEquals(0, ctrl.listAttendees.size());
		System.assertEquals(null, ctrl.attendeeFromId(null));
		System.assertEquals(null, ctrl.IdCaptainForContactIdAttendee(null));
		System.assertEquals(null, ctrl.fAddTicketPurchase);
		System.assertEquals(true, ctrl.IsCaptainContact);
		System.assertEquals(null, ctrl.strCreditCardValidateURL);
		System.assertNotEquals(null, ctrl.strPaymentProcessorPageHeight);
		System.assertNotEquals(null, ctrl.strPaymentProcessorWindowParameters);
		System.assertEquals(false, ctrl.fShowPaymentProcessorOnPage);

		System.assertEquals(null, ctrl.fShowPanelCreditCard);
		ctrl.ShowPanelCreditCard();
		System.assertEquals(true, ctrl.fShowPanelCreditCard);


		ctrl.ChangeAttendeeLookup();
		ctrl.ChangeCaptainLookup();
		ctrl.Close();
		ctrl.SaveAttendeeInfo();
		ctrl.SearchAttendeeLookup();

		// set a contact
		ctrl.contactIdAttendee = contact.Id;
		ctrl.ChangeAttendeeLookup();
		System.assertEquals('Johnny Test', ctrl.strNameAttendee);
		System.assert(ctrl.attendeeEdit != null);
		System.assert(ctrl.attendeeEdit.con.Id == contact.Id);
		System.assert(ctrl.attendeeEdit.cm != null);

		// save a Contact's ticket purchase
		ctrl.fAddTicketPurchase = true;
		ctrl.oppTicketAttendee.Amount = 100;
		ctrl.oppTicketAttendee.Number_of_Tickets__c = 4;
		ctrl.oppTicketAttendee.StageName = 'Won Closed';
		ctrl.SaveAttendeeInfo();
		System.assert(ctrl.strSaveResults != null);

		// verify the ticket opp and ocr
		List<Opportunity> listOpp = [SELECT Id, Name, Amount FROM Opportunity];
		System.assertEquals(1, listOpp.size());
		List<OpportunityContactRole> listOCR = [SELECT Id, ContactId FROM OpportunityContactRole WHERE IsPrimary=TRUE];
		System.assertEquals(1,listOCR.size());
		System.assertEquals(contact.Id, listOCR[0].ContactId);

		// verify the campaignmember
		List<CampaignMember> listCM = [SELECT ContactId, CampaignId, Auction_Ticket_OppId__c, Table_Captain__c FROM CampaignMember
			WHERE ContactId = :contact.Id AND CampaignId = :ctrl.auctionMaintenance.campaignIdAuctionAttendees];
		System.assertEquals(1, listCM.size());
		System.assertEquals(null, ctrl.IdCaptain);
		ctrl.contactIdAttendee = contact.Id;
		ctrl.ChangeAttendeeLookup();
		System.assertEquals(contact.Id, ctrl.IdCaptainForContactIdAttendee(contact.Id));
		System.assertEquals(contact.Id, ctrl.IdCaptain);
		System.assertEquals('Johnny Test', ctrl.strNameCaptain);
		System.assertEquals(4, ctrl.listAttendees.size());
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.IdCaptain = null;
		ctrl.ChangeCaptainLookup();
		System.assertEquals(0, ctrl.listAttendees.size());

		// test search functionality
		ctrl.searchAttendee = 'A bogus name you will not find!';
		ctrl.SearchAttendeeLookup();
		System.assertEquals(null, ctrl.contactIdAttendee);
		ctrl.searchAttendee = 'Johnny Test';
		ctrl.SearchAttendeeLookup();
		System.assertEquals(contact.Id, ctrl.contactIdAttendee);
		System.assertEquals(contact.Id, ctrl.IdCaptain);
		System.assertEquals(4, ctrl.listAttendees.size());

		// save a new contact as an attendee
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.attendeeEdit.con.FirstName = 'Janey';
		ctrl.attendeeEdit.con.LastName = 'Test';
		System.assertEquals(contact.Id, ctrl.attendeeEdit.cm.Table_Captain__c);
		System.assertEquals(null, ctrl.strSaveResults);
		ctrl.SaveAttendeeInfo();
		System.assert(ctrl.strSaveResults != null);
		System.assert(ctrl.contactIdAttendee != null);
		System.assert(ctrl.contactIdAttendee != contact.Id);
		System.assertEquals(true, ctrl.IsCaptainContact);
		System.assertEquals(contact.Id, ctrl.IdCaptainForContactIdAttendee(ctrl.contactIdAttendee));

		// test out an account table captain
		Account acc2 = new Account(Name='Another Test Account');
		insert acc2;
		Opportunity opp = new Opportunity(
			RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
			CampaignId = ctrl.auctionMaintenance.campaignIdAuctionTickets
		);
		opp.AccountId = acc2.Id;
		opp.Amount = 1000;
		opp.StageName = 'Won Closed';
		opp.Number_of_Tickets__c = 10;
		opp.Name = 'my test account ticket purchase';
		opp.CloseDate = System.today();
		insert opp;
		ctrl.IdCaptain = acc2.Id;
		ctrl.ChangeCaptainLookup();
		System.assertEquals('Another Test Account', ctrl.strNameCaptain);
		System.assertEquals(false, ctrl.IsCaptainContact);
		System.assertEquals(acc2.Id, ctrl.IdCaptain);
		System.assert(ctrl.listOppCaptain != null);
		System.assertEquals(ctrl.listOppCaptain[0].Id, opp.Id);
		System.debug(ctrl.listAttendees);
		System.assertEquals(10, ctrl.listAttendees.size());

		// save another contact to the account table
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.IdCaptain = acc2.Id;
		ctrl.ChangeCaptainLookup();
		ctrl.attendeeEdit.con.FirstName = 'Joey';
		ctrl.attendeeEdit.con.LastName = 'Test';
		System.assertEquals(null, ctrl.strSaveResults);
		ctrl.SaveAttendeeInfo();
		System.assert(ctrl.strSaveResults != null);
		System.assertEquals(opp.Id, ctrl.attendeeEdit.cm.Auction_Ticket_OppId__c);
		System.assert(ctrl.contactIdAttendee != null);
		System.assertEquals(acc2.Id, ctrl.IdCaptainForContactIdAttendee(ctrl.contactIdAttendee));

		// test remoting functions
		System.assert(AUC_CTRL_AuctionCheckIn.getListContacts('Test').size() >= 3);
		System.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Johnny Test').size() >= 1);
		System.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Another Test Account').size() >= 1);
		System.assert(AUC_CTRL_AuctionCheckIn.getListAttendees(ctrl.auctionId, 'Test').size() >= 1);

		ctrl.NextGuest();
		System.assert(ctrl.contactIdAttendee == null);

	}

}