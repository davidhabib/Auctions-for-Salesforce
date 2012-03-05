// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionReceipts {

	// constructor
	public AUC_CTRL_AuctionReceipts() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;	
		} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = listSOAuctions[1].getValue();
		}
		auctionMaintenance.auctionId = auctionId;	

		// also support a specific contact (to allow page to be invoked on a specific receipt)
		String strcontactId = ApexPages.currentPage().getParameters().get('contactId');
		if (strcontactId != null && strcontactId != '') {
			contactIdPurchaser = strcontactId;
			fIncludeTicketPurchases = true;
		}
		
		fIncludeAllGuests = false;
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	
 	public String getRenderFormat() {
    	if (ApexPages.currentPage().getParameters().get('RenderFormat') == 'pdf')
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
	
	public boolean fIncludeAllGuests { get; set; }
	
	public string strAuctionReceiptsIntro { get {return AUC_AuctionConstants.StrAuctionReceiptsIntro();} }
	
	public string strAuctionReceiptsFooter { get {return AUC_AuctionConstants.StrAuctionReceiptsFooter();} }
	
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }

	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		listReceipts = null;
		listReceipts2 = null;
		contactIdPurchaser = null;
		//strSaveResults = null;
		return null;
	}

	// holds the currently selected Purchaser contact
	// has to be a string to allow a null Id ('') to get returned from the page.
	public string contactIdPurchaser { 
		get; 
		set {
			// first invalidate anything dependent on a change
			if (contactIdPurchaser != value) {
				strNamePurchaser = null;
				listReceipts = null;
				listReceipts2 = null;
			}
			contactIdPurchaser = value;
			if (contactIdPurchaser == '') contactIdPurchaser = null;
			if (contactIdPurchaser != null)	fIncludeAllGuests = false;
		}		
	}
	
	// holds the currently selected Purchaser's name	
	public string strNamePurchaser { 
		get {
			if (strNamePurchaser == null && contactIdPurchaser != null) {
				Contact con = [select Name from Contact where Id = :contactIdPurchaser];
				strNamePurchaser = con.Name;
			}
			return strNamePurchaser;
		}
		private set;
	}
			
	// callback when the user changes the Purchaser contact lookup.
	public PageReference ChangePurchaserLookup() {
		// clear any previous save message
		//strSaveResults = null;
		
		// the setter for contactIdPurchaser will 
		// automatically invalidate any dependencies!
		return null;
	}  
	
	// this parameter is used in scenarios where the page
	// needs us to search for an Purchaser before it could wait
	// for the return from its javascript remoting call to get data
	public string searchPurchaser { get; set; }
	
	// callback when the user changes the Attendee contact lookup and submits too quick.
	public PageReference SearchPurchaserLookup() {
		if (searchPurchaser != null && searchPurchaser != '') {
			list<Contact> listCon = [select Id from Contact where Name = :searchPurchaser];
			if (listCon.size() > 0) {
				contactIdPurchaser = listCon[0].Id;
			} else {
				contactIdPurchaser = null;
				//strSaveResults = null;
				strNamePurchaser = searchPurchaser; // to keep displaying the text.
				return null;
			}
		} else {
			contactIdPurchaser = null;	
			strNamePurchaser = null;		
		}
		return ChangePurchaserLookup();
	}

	public PageReference ChangeIncludeTicketPurchases() {
		listReceipts = null;
		listReceipts2 = null;
		return null;
	}

	public PageReference ChangeIncludeAllGuests() {
		listReceipts = null;
		listReceipts2 = null;
		contactIdPurchaser = null;
		strNamePurchaser = null;
		searchPurchaser = null;
		return null;
	}

	public Boolean HasReceipts {
		get { 
			if (listReceipts == null) return False;
			if (listReceipts.size() == 0) return False;
			return True;
		}
	}
	
	public string strErrorMessage { get; set; }
	
	// list of Receipt objects to display
	public list<Receipt> listReceipts {
		get { 
			if (listReceipts != null) return listReceipts;
			
			// create the lists of which contacts to include
			list<ID> listContactId = new list<ID>();
			list<ID> listContactId2 = new list<ID>();
			integer cOverLimit = 0;
			strErrorMessage = null;
			
			if (contactIdPurchaser != null) {
				listContactId.add(contactIdPurchaser);
			} else if (fIncludeAllGuests) {			
				list<AUC_CTRL_AuctionCheckOut.Purchaser> listPurchasers = getListPurchasers(auctionId, '');
				integer cPurchaser = 0;
				for (AUC_CTRL_AuctionCheckOut.Purchaser p : listPurchasers) {
					cPurchaser++;
					if (cPurchaser <= 1000)
						listContactId.add(p.contactId);
					else if (cPurchaser <= 2000)
						listContactId2.add(p.contactId);
					else // after 2000, we ignore them!
						cOverLimit++;
				}
			}
			
			// call the real worker.
			listReceipts = listReceiptsForlistContactId(listContactId);
			listReceipts2 = listReceiptsForlistContactId(listContactId2);
			if (cOverLimit > 0) {
				strErrorMessage = 'Receipts were printed for ' + string.valueOf(listReceipts.size() + listReceipts2.size()) +
					' guests.  Auction Receipts has hit its limit, and the last potential ' + string.valueOf(cOverLimit) +
					' receipts were not included.';
			}
			
			return listReceipts;
		}	
	
		set;		
	}
			
	// to handle large auctions, the second list of Receipt objects to display
	public list<Receipt> listReceipts2 {
		get {
			// we fill listReceipts2 at the same time we fill listReceipts1.
			return listReceipts2;
			
			/*
			if (listReceipts2 != null) return listReceipts2;
			
			//if (listSOPurchasers2 == null) return null;
			
			// create the list of which contacts to include
			list<ID> listContactId = new list<ID>();
			if (contactIdPurchaser == null) {
				for (SelectOption so : listSOPurchasers2) {
					if (so.getValue() != '') {
						listContactId.add(so.getValue());
					}
				}
			}
			
			// call the real worker.
			listReceipts2 = listReceiptsForlistContactId(listContactId);
			return listReceipts2;
			*/
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
				opportunity.Auction_Non_Deductible_Amount__c,			
				opportunity.IsWon, opportunity.RecordTypeId, opportunity.RecordType.Name, opportunity.Description from OpportunityContactRole 
				where IsPrimary=true and contactId in :listContactId and
					(((opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem or opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionGift) 
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionAttendees)
					or 
					(opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionTicket
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets
						and IsPrimary=:fIncludeTicketPurchases)) 
				order by contact.LastName, contact.FirstName]) {
	       
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
		        		r.listOppAuctionPurchases = new list<Opportunity>();
		        		r.strContactName = ocr.Contact.Name;
		        		r.strContactFirstName = ocr.Contact.FirstName;
		        		r.dtAuction = dtAuction;
		        		mapContactIdReceipt.put(r.contactId, r);
		        		listReceiptsT.add(r);
		        	}
	        		r.listOppAuctionPurchases.add(ocr.opportunity);
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
		public list<Opportunity> listOppAuctionPurchases { get; set; }
		
		public String strPageTitle {
			get { 
				return UserInfo.getOrganizationName() + ' Auction receipt for ' + strContactName;
			}
		}			
	}

	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts who purchased Auction Items
	* or Auction Tickets on the specified auction, optionally filtered by strFilter.
	* @param auctionId the Auction to filter by 
	* @param strFilter the substring to filter by 
	* @return list<Purchaser>, which will be turned into a Javascript collection.
	********************************************************************************************************/
   @RemoteAction global static list<AUC_CTRL_AuctionCheckOut.Purchaser> getListPurchasers(string auctionId, string strFilter) {
   		return AUC_CTRL_AuctionCheckOut.getListPurchasers(auctionId, strFilter);
   }



	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {

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
		PageReference p = new PageReference('Page.AuctionReceipts');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionReceipts ctrl = new AUC_CTRL_AuctionReceipts();
		
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
		
		ctrl.contactIdPurchaser = contact2.id;
		ctrl.ChangePurchaserLookup();
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
		ctrl.contactIdPurchaser = null;
		ctrl.ChangePurchaserLookup();
		System.AssertEquals(bigNum+1, ctrl.listReceipts.size());
		test.stopTest();
	}	
}