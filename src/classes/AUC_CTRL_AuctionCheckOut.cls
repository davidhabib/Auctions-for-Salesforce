// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionCheckOut {

	// constructor
	public AUC_CTRL_AuctionCheckOut() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;	
		} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = listSOAuctions[1].getValue();
		}
		auctionMaintenance.auctionId = auctionId;	
		
		fIncludeTicketPurchases = true;
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	
 	public String getRenderFormat() {
    	if (ApexPages.currentPage().getParameters().get('RenderFormat') != null)
        	return 'pdf';
        else
         	return null;
    } 
     
    public PageReference OpenPDF() {
		PageReference pdf =  ApexPages.currentPage();
        pdf.getParameters().put('RenderFormat','pdf');
        return pdf;
    }  	
	
 	// the currently selected Auction
	public Id auctionId { get; set; }
	
	public boolean fIncludeTicketPurchases { get; set; }
	
	public string strAuctionReceiptsIntro { get {return AUC_AuctionConstants.StrAuctionReceiptsIntro();} }
	
	public string strAuctionReceiptsFooter { get {return AUC_AuctionConstants.StrAuctionReceiptsFooter();} }
	
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }
	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		listSOPurchasers = null;
		listSOPurchasers2 = null;
		listReceipts = null;
		listReceipts2 = null;
		contactId = null;
		return null;
	}

	// the currently selected Contact
	public Id contactId { get; set; }

	// the list of contacts with any purchases or tickets
	public list<SelectOption> listSOPurchasers{
		get {
			if (listSOPurchasers != null) return listSOPurchasers;
			listSOPurchasers = new list<SelectOption>();
			listSOPurchasers.add(new SelectOption('', ''));

			// use a set to avoid dups
			set<ID> setContactId = new set<ID>();
			set<ID> setContactId2 = new set<ID>();

			// in one soql call, get all the appropriate opportunities for auction purchases and tickets
			// we are not looking at fIncludeTicketPurchases on purpose; we still want those folks in the list.
			for (list<OpportunityContactRole> listOCR : [select contactId, contact.Name from OpportunityContactRole 
				where IsPrimary=true and 
					(opportunity.campaignId=:auctionMaintenance.campaignIdAuctionAttendees
						or opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets) 
				order by contact.Name]) {
				
				for (OpportunityContactRole ocr : listOCR) {
					if (setContactId.contains(ocr.contactId) || setContactId2.contains(ocr.contactId))
						continue;
					if (setContactId.size() < 999 && setContactId.add(ocr.contactId)) {
						listSOPurchasers.add(new SelectOption(ocr.contactId, ocr.Contact.Name));
					} else if (setContactId2.add(ocr.contactId)) {
						if (listSOPurchasers2 == null) listSOPurchasers2 = new list<SelectOption>();
						listSOPurchasers2.add(new SelectOption(ocr.contactId, ocr.Contact.Name));						
					}
				}
			}		

			return listSOPurchasers;
		}
		set;
	}	

	// in order to support lists of attendees and purchasers > 1000, we need a second list.
	public list<SelectOption> listSOPurchasers2 { get; set; }

	
	public PageReference ChangeAttendee() {
		listReceipts = null;
		listReceipts2 = null;
		return null;
	}
	
	public PageReference ChangeIncludeTicketPurchases() {
		listReceipts = null;
		listReceipts2 = null;
		return null;
	}

	public Boolean HasReceipts {
		get {
			if (listReceipts == null) return False;
			if (listReceipts.size() == 0) return False;
			return True;
		}
	}
	
	// list of Receipt objects to display
	public list<Receipt> listReceipts {
		get {
			if (listReceipts != null) return listReceipts;
			
			// create the list of which contacts to include
			list<ID> listContactId = new list<ID>();
			if (contactId != null) {
				listContactId.add(contactId);
			}
			// call the real worker.
			listReceipts = listReceiptsForlistContactId(listContactId);
			return listReceipts;
		}	
	
		set;		
	}
			
	// to handle large auctions, the second list of Receipt objects to display
	public list<Receipt> listReceipts2 {
		get {
			if (listReceipts2 != null) return listReceipts2;
			
			if (listSOPurchasers2 == null) return null;
			
			// create the list of which contacts to include
			list<ID> listContactId = new list<ID>();
			if (contactId == null) {
				for (SelectOption so : listSOPurchasers2) {
					if (so.getValue() != '') {
						listContactId.add(so.getValue());
					}
				}
			}
			
			// call the real worker.
			listReceipts2 = listReceiptsForlistContactId(listContactId);
			return listReceipts2;
		}	
	
		set;		
	}
			
	// this is the core of the work.  Getting a list of Receipts for contacts who made purchases.
	// each receipt contains a list of the opportunities for the contact.
	// this allows us to use two apex:repeat constructs to loop through the contacts, and all of their opps.
	private list<Receipt> listReceiptsForlistContactId(list<ID> listContactId) {			
			
			list<Receipt> listReceiptsT = new list<Receipt>();

			
			Date dtAuction = AUC_AuctionMaintenance.DateOfAuctionId(auctionId);

	       	map<ID, Receipt> mapContactIdReceipt = new map<ID, Receipt>();

			// in one soql call, get all the appropriate opportunities for auction purchases and tickets
			for (list<OpportunityContactRole> listOCR : [select contactId, contact.Name, contact.FirstName, opportunityId, opportunity.Id, 
				opportunity.name, opportunity.Amount, opportunity.Auction_Item_Name__c, opportunity.Auction_Deductible_Amount__c, 				
				opportunity.IsWon, opportunity.RecordTypeId, opportunity.RecordType.Name, opportunity.Description from OpportunityContactRole 
				where IsPrimary=true and contactId in :listContactId and
					(((opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem or opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionGift) 
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionAttendees)
					or 
					(opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionTicket
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets
						and IsPrimary=:fIncludeTicketPurchases)) 
				order by contact.Name]) {
	       
				// now go through all the opps, and for each contact create the appropriate Receipt objects and their child opportunities.	       
		        for (OpportunityContactRole ocr : listOCR){
		        	Opportunity opp = ocr.Opportunity;
	
		        	//system.debug('DUMPING OCR Info ------------------------------------------------------');	        	
		        	//system.debug(ocr.contactId);
		        	//system.debug(ocr.opportunity.name);
		        	//system.debug(ocr.opportunity.amount);
		        	//system.debug(ocr.opportunity.Auction_Item_Name__c);
		        	//system.debug(opp.name);
		        	
		        	// this map keeps track of whether we've already created a receipt for this contact or not.
		        	Receipt r = mapContactIdReceipt.get(ocr.contactId);
		        	if (r == null) {
		        		r = new Receipt();
		        		r.contactId = ocr.contactId;
		        		r.auctionId = auctionId;
		        		r.listOppAuctionPurchases = new list<AUC_PurchaseOpportunity>();
		        		r.strContactName = ocr.Contact.Name;
		        		r.strContactFirstName = ocr.Contact.FirstName;
		        		r.dtAuction = dtAuction;
		        		mapContactIdReceipt.put(r.contactId, r);
		        		listReceiptsT.add(r);
		        	}
	        		r.listOppAuctionPurchases.add(new AUC_PurchaseOpportunity(ocr.opportunity));
	        		if (opp.Amount <> null) r.decTotalAmountPaid += opp.Amount;
					r.decTotalAmountDeductible += opp.Auction_Deductible_Amount__c;
					//if (opp.IsWon) r.decTotalAmountReceived += opp.Amount;
		        }
	        }
	        
	        //system.debug('**** Leaving listReceipts');
	        return listReceiptsT;
	}

	//==================== Receipt Class ======================================
	// helper class that holds a contact, and their opportunities
	// the VF Page will iterate through a list of these that the controller provides.
	public class Receipt {
		
		// constructor
		public Receipt() {
			//system.debug('**** Creating Receipt');
			decTotalAmountPaid = 0;
			decTotalAmountDeductible = 0;	
			//decTotalAmountReceived = 0;
		}
		
		public ID contactId { get; set; }
		public String strContactName { get; set; }
		public String strContactFirstName { get; set; }		
		public ID auctionId { get; set; }
		public Date dtAuction { get; set; }
		public Decimal decTotalAmountPaid { get; set; }
		public Decimal decTotalAmountDeductible { get; set; }
		//public Decimal decTotalAmountReceived { get; set; }
		public list<AUC_PurchaseOpportunity> listOppAuctionPurchases { get; set; }
		
		public String strPageTitle {
			get { 
				return UserInfo.getOrganizationName() + ' Auction receipt for ' + strContactName;
			}
		}			
	}


	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
		
		//UNDONE: these tests haven't been updated for this page.
		// they were just grabbed from AuctionReceipts.
		return;

    	// create needed data
    	Account acc = new Account(Name='My Test Account');
    	insert acc;    	
    	Contact contact1 = new Contact(Firstname='David', Lastname='Test', AccountId=acc.Id);
    	insert contact1;
    	Contact contact2 = new Contact(Firstname='John', Lastname='Test', AccountId=acc.Id);
    	insert contact2;
    	
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	
    	CampaignMember cm1 = new CampaignMember();
    	cm1.CampaignId = campaign.id;
    	cm1.ContactId = contact1.id;
    	insert cm1;
    	
    	CampaignMember cm2 = new CampaignMember();
    	cm2.CampaignId = campaign.id;
    	cm2.ContactId = contact2.id;
    	insert cm2;
    	
    	Auction_Item__c ai = new Auction_Item__c (
    		Auction_Item_Name__c = 'Test Auction Item',
    		Auction__c = auction.id,
    		FMV_Override__c = 100
    	);
    	insert ai;
    	    	
		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;
		System.assertEquals(campaign.Id, am.campaignIdAuctionAttendees);

    	Opportunity oppPurchase= new Opportunity (
    		Name = 'My Auction Item Purchase',
    		CampaignId = campaign.id,
    		RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
    		StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE,
    		CloseDate = System.Today(),
    		Amount = 150,
    		Auction_Item_Purchased__c = ai.Id,
    		Auction_Non_Deductible_Amount__c = 100
    	);
    	insert oppPurchase;
    	system.AssertEquals(150, oppPurchase.Amount);
    	system.AssertEquals(100, oppPurchase.Auction_Non_Deductible_Amount__c);
    	
		Opportunity opp = [select Id, Name, Auction_Deductible_Amount__c from Opportunity where Id=:oppPurchase.id];
    	system.AssertEquals(50, opp.Auction_Deductible_Amount__c);
    	
    	OpportunityContactRole oppcr = new OpportunityContactRole();
    	oppcr.ContactId = contact1.id;
    	oppcr.OpportunityId = oppPurchase.id;
    	oppcr.IsPrimary = true;
    	insert oppcr;
		
		//point to our VF page
		PageReference p = new PageReference('Page.AuctionCheckOut');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionCheckOut ctrl = new AUC_CTRL_AuctionCheckOut();
		
		System.AssertEquals(auction.id, ctrl.auctionId);
		ctrl.ChangeAuction();
		System.AssertEquals(auction.id, ctrl.auctionId);

		system.AssertEquals(null, ctrl.getRenderFormat());
		system.Assert(ctrl.OpenPDF() != null);
		
		system.Assert(ctrl.listReceipts != null);
		Receipt r = ctrl.listReceipts[0];
		system.Assert(r.contactId == contact1.id);
		system.AssertEquals(system.Today(), r.dtAuction);
		system.Assert(r.strPageTitle.contains('David Test')); 
		system.AssertEquals('David', r.strContactFirstName);
		system.AssertEquals('David Test', r.strContactName);
		system.Assert(r.listOppAuctionPurchases != null);
		system.Assert(r.listOppAuctionPurchases.size() == 1);
		system.AssertEquals(150, r.decTotalAmountPaid);
		system.AssertEquals(50, r.decTotalAmountDeductible);
		system.Assert(ctrl.HasReceipts);
		
		ctrl.contactId = contact2.id;
		ctrl.ChangeAttendee();
		system.Assert(ctrl.listReceipts != null);
		system.Assert(ctrl.listReceipts.size() == 0); // since contact2 has no purchases.
		system.Assert(ctrl.HasReceipts == false);
		
		//now do some tests with large sets of data
		// SET bigNum to ~110 to test large data but stay under limits
		integer bigNum = 10;
		Integer i;
		list<Contact> listContact = new list<Contact>();
		for (i =0; i < bigNum; i++) {
			Contact c = new Contact(LastName='tester'+i, AccountId=acc.Id);
			listContact.add(c);
		}
		insert listContact;
		
		list<Opportunity> listOppPurchases = new list<Opportunity>();
		for (i=0; i<bigNum; i++) {
	    	Opportunity oppAIP= new Opportunity (
	    		Name = 'My Auction Item Purchase',
	    		CampaignId = campaign.id,
	    		RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
	    		StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE,
	    		CloseDate = System.Today(),
	    		Amount = 150,
	    		Auction_Item_Purchased__c = ai.Id,
	    		Auction_Non_Deductible_Amount__c = 100
	    	);
	    	listOppPurchases.add(oppAIP);			
		}
		insert listOppPurchases;
		
		list<OpportunityContactRole> listOppCR = new list<OpportunityContactRole>();
		for (i=0; i<bigNum; i++) {
	    	OpportunityContactRole ocr = new OpportunityContactRole();
	    	ocr.ContactId = listContact[i].id;
	    	ocr.OpportunityId = listOppPurchases[i].id;
	    	ocr.IsPrimary = true;
			listOppCR.add(ocr);
		}
		insert listOppCR;
		
		list<CampaignMember> listCM = new list<CampaignMember>();
		for (i=0; i<bigNum; i++) {
			CampaignMember cmT = new CampaignMember();
    		cmT.CampaignId = campaign.id;
    		cmT.ContactId = listContact[i].id;
    		listCM.add(cmT);
		}
		test.startTest();
		insert listCM;
		
		ctrl.ChangeAuction();
		System.AssertEquals(auction.id, ctrl.auctionId);
		ctrl.contactId = null;
		ctrl.ChangeAttendee();
		System.AssertEquals(bigNum+1, ctrl.listReceipts.size());
		test.stopTest();
	}	
}