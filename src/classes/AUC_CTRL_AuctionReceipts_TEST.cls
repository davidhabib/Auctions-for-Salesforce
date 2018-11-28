// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionReceipts_TEST {

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

		Campaign campaign = [SELECT Id, Auction__c FROM Campaign
			WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees
			AND Auction__c = :auction.Id];
		System.assertEquals(auction.Id, campaign.Auction__c);

		CampaignMember cm1 = new CampaignMember();
		cm1.CampaignId = campaign.Id;
		cm1.ContactId = contact1.Id;
		cm1.Bid_Number__c = 101;
		insert cm1;

		CampaignMember cm2 = new CampaignMember();
		cm2.CampaignId = campaign.Id;
		cm2.ContactId = contact2.Id;
		cm2.Bid_Number__c = 102;
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
			StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE,
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
		PageReference p = new PageReference('Page.AuctionReceipts');
		p.getParameters().put('auctionId', auction.Id);
		p.getParameters().put('IncludeAll', 'true');
		p.getParameters().put('IncludeTickets', 'true');
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionReceipts ctrl = new AUC_CTRL_AuctionReceipts();

		System.assertEquals(auction.Id, ctrl.auctionId);
		ctrl.ChangeAuction();
		System.assertEquals(auction.Id, ctrl.auctionId);

		System.assertEquals('/apex/GW_Auctions__AuctionReceipts?RenderFormat=pdf&auctionId=' +
			auction.Id + '&IncludeAll=true&IncludeTickets=true',
			ctrl.strOpenReceiptURL);
		ctrl.fIncludeAllGuests = true;
		System.assertEquals(ctrl.fHasHouseholds, ctrl.fHasHouseholds);
		System.assertEquals(ctrl.strAuctionReceiptsIntro, ctrl.strAuctionReceiptsIntro);
		System.assertEquals(ctrl.strAuctionReceiptsFooter, ctrl.strAuctionReceiptsFooter);
		System.assertEquals(null, ctrl.getRenderFormat());
		System.assert(ctrl.listReceipts == null);
		ctrl.fOpenPDF = true;
		System.assert(ctrl.listReceipts != null);
		System.assertEquals(1, ctrl.listReceipts.size());
		System.assertEquals(1, ctrl.listLR.size());
		AUC_CTRL_AuctionReceipts.Receipt r = ctrl.listReceipts[0];
		System.assert(r.contactId == contact1.Id);
		System.assertEquals(System.today(), r.dtAuction);
		System.assert(r.strPageTitle.contains('David Test'));
		System.assertEquals('David', r.strContactFirstName);
		System.assertEquals('David Test', r.strContactName);
		System.assert(r.listOppAuctionPurchases != null);
		System.assert(r.listOppAuctionPurchases.size() == 1);
		System.assertEquals(150, r.decTotalAmountPaid);
		System.assertEquals(50, r.decTotalAmountDeductible);
		System.assert(ctrl.HasReceipts);

		ctrl.contactIdPurchaser = contact2.Id;
		ctrl.ChangePurchaserLookup();
		System.assert(ctrl.listReceipts != null);
		System.assert(ctrl.listReceipts.size() == 0); // since contact2 has no purchases.
		System.assert(ctrl.HasReceipts == false);

		//now do some tests with large sets of data
		// SET bigNum to ~110 to test large data but stay under limits
		Integer bigNum = 10;
		Integer i;
		List<Contact> listContact = new List<Contact>();
		for (i =0; i < bigNum; i++) {
			Contact c = new Contact(LastName='tester'+i, AccountId=acc.Id);
			listContact.add(c);
		}
		insert listContact;

		List<Opportunity> listOppPurchases = new List<Opportunity>();
		for (i=0; i<bigNum; i++) {
			Opportunity oppAIP= new Opportunity (
				Name = 'My Auction Item Purchase',
				CampaignId = campaign.Id,
				RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
				StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE,
				CloseDate = System.today(),
				Amount = 150,
				Auction_Item_Purchased__c = ai.Id,
				Auction_Non_Deductible_Amount__c = 100
			);
			listOppPurchases.add(oppAIP);
		}
		insert listOppPurchases;

		List<OpportunityContactRole> listOppCR = new List<OpportunityContactRole>();
		for (i=0; i<bigNum; i++) {
			OpportunityContactRole ocr = new OpportunityContactRole();
			ocr.ContactId = listContact[i].Id;
			ocr.OpportunityId = listOppPurchases[i].Id;
			ocr.IsPrimary = true;
			listOppCR.add(ocr);
		}
		insert listOppCR;

		List<CampaignMember> listCM = new List<CampaignMember>();
		for (i=0; i<bigNum; i++) {
			CampaignMember cmT = new CampaignMember();
			cmT.CampaignId = campaign.Id;
			cmT.ContactId = listContact[i].Id;
			listCM.add(cmT);
		}
		Test.startTest();
		insert listCM;

		ctrl.ChangeAuction();
		System.assertEquals(auction.Id, ctrl.auctionId);
		ctrl.contactIdPurchaser = null;
		ctrl.ChangePurchaserLookup();
		ctrl.fIncludeAllGuests = true;
		System.assertEquals(bigNum+1, ctrl.listReceipts.size());
		System.assert(ctrl.listReceipts2 != null);
		System.assert(ctrl.listReceipts2.size() == 0);
		System.assert(ctrl.listReceipts3 != null);
		System.assert(ctrl.listReceipts3.size() == 0);

		System.assertEquals(null, ctrl.strNamePurchaser);
		System.assertEquals(null, ctrl.searchPurchaser);
		ctrl.SearchPurchaserLookup();
		System.assertEquals(null, ctrl.contactIdPurchaser);
		ctrl.searchPurchaser = 'not to be found!';
		ctrl.SearchPurchaserLookup();
		System.assertEquals(null, ctrl.contactIdPurchaser);
		ctrl.searchPurchaser = 'David Test';
		ctrl.SearchPurchaserLookup();
		System.assertEquals(false, ctrl.fIncludeAllGuests);
		System.assertEquals(contact1.Id, ctrl.contactIdPurchaser);
		System.assertEquals('David Test', ctrl.strNamePurchaser);
		ctrl.ChangeIncludeTicketPurchases();
		ctrl.ChangeIncludeAllGuests();
		ctrl.ChangeAddressToHousehold();

		Test.stopTest();
	}

}