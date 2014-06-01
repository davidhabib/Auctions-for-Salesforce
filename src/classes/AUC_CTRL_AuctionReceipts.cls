// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionReceipts {

	// constructor
	public AUC_CTRL_AuctionReceipts() {
		
		// force IE into Standards Mode
		Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		 		
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;	
		} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = listSOAuctions[1].getValue();
		}
		auctionMaintenance.auctionId = auctionId;	

		// default state
		fIncludeTicketPurchases = false;
		fIncludeAllGuests = false;
		contactIdPurchaser = null;
				
		// also support a specific contact (to allow page to be invoked on a specific receipt)
		String strcontactId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('contactId'));
		if (strcontactId != null && strcontactId != '') {
			contactIdPurchaser = strcontactId;
		}

		// IncludeAll parameter 
		String fAll = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('IncludeAll'));
		if (fAll != null && fAll == 'true') {
			fIncludeAllGuests = true;
		}

		// IncludeTickets parameter 
		String fTickets = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('IncludeTickets'));
		if (fTickets != null && fTickets == 'true') {
			fIncludeTicketPurchases = true;
		}
		
		getRenderFormat();
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	
 	public String getRenderFormat() {
    	if (ApexPages.currentPage().getParameters().get('RenderFormat') == 'pdf') {
        	fOpenPDF = true;
        	return 'pdf';
    	} else {
    		fOpenPDF = false;
         	return null;
    	}
    } 
     
    public PageReference OpenPDF() {
		PageReference pdf =  ApexPages.currentPage();
        pdf.getParameters().put('RenderFormat','pdf');
        fOpenPDF = true;
        return pdf;
    }  
    
	// public property to get the commandButton URL
	// for the Open button, to open the receipts pdf  
	public string strOpenReceiptURL {
		get {
			string str =  '/apex/GW_Auctions__AuctionReceipts' +
	        	'?RenderFormat=pdf' +
	        	'&auctionId=' + auctionId;
	        	
			if (contactIdPurchaser != null) {	        	
	        	str += '&contactId=' + contactIdPurchaser;
			}
			if (fIncludeAllGuests == true) {
				str += '&IncludeAll=true';
			}
			if (fIncludeTicketPurchases == true) {
				str += '&IncludeTickets=true';
			}
			return str;			
		}
		private set;
	}
	    		
	private boolean fOpenPDF { get; set; }
	
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
		listReceipts3 = null;
		listLR = null;
		contactIdPurchaser = null;
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
				listReceipts3 = null;
				listLR = null;
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

			// need to search by both contact name and bid number
			decimal decBid = -1;
			try {
				decBid = decimal.valueOf(searchPurchaser);
			} catch (Exception ex) {}
			list<CampaignMember> listCM = [select contactId, contact.Name, Bid_Number__c from CampaignMember 
				where (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees or
						CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
					and contactId <> null
					and (contact.Name = :searchPurchaser or Bid_Number__c = :decBid)];
			if (listCM.size() > 0) {
				contactIdPurchaser = listCM[0].contactId;
			} else {
				contactIdPurchaser = null;
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
		listReceipts3 = null;
		listLR = null;
		return null;
	}

	public PageReference ChangeIncludeAllGuests() {
		listReceipts = null;
		listReceipts2 = null;
		listReceipts3 = null;
		listLR = null;
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
	
	// helper routine to return all Opportunity field names from the Field Set
	private string strOppFields {
		get {
			if (strOppFields == null) {
				
				// initialize the list of all fields on Opportunity.
				// ideally, we'd only include the fields in the Field Set,
				// but our page needs multiple opp fields, so it is easier to get them all.
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Opportunity.fields.getMap();
				list<string> listStrFields = new list<string>();
				listStrFields.addAll(mapS.keySet());  
				strOppFields = '';
				for (string str : listStrFields) {
					strOppFields += 'opportunity.' + str + ',';
				}  		
				strOppFields = strOppFields.substring(0, strOppFields.length()-1);
			}
			return strOppFields;
		}
		set;
	}
	
	
	public string strErrorMessage { get; set; }
	
	// list of Receipt objects to display
	public list<Receipt> listReceipts {
		get { 
			if (listReceipts != null) return listReceipts;
			
			// if we aren't opening the pdf, then bail out!
			if (!fOpenPDF) return null;
			
			// create the lists of which contacts to include
			list<ID> listContactId = new list<ID>();
			list<ID> listContactId2 = new list<ID>();
			list<ID> listContactId3 = new list<ID>();
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
					else if (cPurchaser <= 3000)
						listContactId3.add(p.contactId);
					else // after 3000, we ignore them!
						cOverLimit++;
				}
			}
			
			// call the real worker.
			listReceipts = listReceiptsForlistContactId(listContactId);
			listReceipts2 = listReceiptsForlistContactId(listContactId2);
			listReceipts3 = listReceiptsForlistContactId(listContactId3);
			if (cOverLimit > 0) {
				strErrorMessage = 'Receipts were printed for ' + 
					string.valueOf(listReceipts.size() + listReceipts2.size() + ListReceipts3.size()) +
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
		}		
		private set;		
	}
	
	// to handle large auctions, the third list of Receipt objects to display
	public list<Receipt> listReceipts3 {
		get {
			// we fill listReceipts3 at the same time we fill listReceipts1.
			return listReceipts3;
		}		
		private set;		
	}

	public list<list<Receipt>> listLR {
		get {
			if (listLR == null) {
				listLR = new list<list<Receipt>>();
				listLR.add(listReceipts);
				listLR.add(listReceipts2);
				listLR.add(listReceipts3);
			}
			return listLR;
		}
		private set;
	}
			
	// this is the core of the work.  Getting a list of Receipts for contacts who made purchases.
	// each receipt contains a list of the opportunities for the contact.
	// this allows us to use two apex:repeat constructs to loop through the contacts, and all of their opps.
	private list<Receipt> listReceiptsForlistContactId(list<ID> listContactId) {
			
			list<Receipt> listReceiptsT = new list<Receipt>();
			Date dtAuction = AUC_AuctionMaintenance.DateOfAuctionId(auctionId);
	       	map<ID, Receipt> mapContactIdReceipt = new map<ID, Receipt>();
	       	string rtPurchase = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem;
	       	string rtGift = AUC_AuctionMaintenance.recordtypeIdAuctionGift;
	       	string rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
	       	string cmpIdAttendees = auctionMaintenance.campaignIdAuctionAttendees;
	       	string cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;
	       	map<ID, integer> mapContactIdBidNumber = new map<ID, integer>();
	       	
	       	// create the map of bid numbers, so we can include them on the report.
	       	list<CampaignMember> listCM = [select contactId, Bid_Number__c from CampaignMember where 
	       		Bid_Number__c <> null and campaignId = :cmpIdAttendees and contactId in :listContactId];
	       	for (CampaignMember cm : listCM) {
	       		mapContactIdBidNumber.put(cm.contactId, integer.valueOf(cm.Bid_Number__c));
	       	}

			string strSoql = 'select contactId, contact.Name, contact.Firstname, contact.MailingStreet, contact.MailingCity, contact.MailingState, contact.MailingPostalCode, ' +
				' opportunity.RecordType.Name, '; 
			if (AUC_AuctionConstants.strContactHouseholdField != null) {
				strSoql += ' contact.' + AUC_AuctionConstants.strContactHouseholdField + ', ';
			}
			if (AUC_AuctionConstants.strContactHouseholdNameField != null) {
				strSoql += ' contact.' + AUC_AuctionConstants.strContactHouseholdNameField + ', ';		
			}
			if (AUC_AuctionConstants.strContactHouseholdGreetingField != null) {
				strSoql += ' contact.' + AUC_AuctionConstants.strContactHouseholdGreetingField + ', ';
			}
			if (AUC_AuctionConstants.isNPSPHouseholdAccountModel) {
				strSoql += ' contact.account.npe01__SYSTEM_AccountType__c, ';
			}
			strSoql += AUC_AuctionMaintenance.StrEscape(strOppFields) +
				' from OpportunityContactRole ' +
				' where IsPrimary=true and contactId in :listContactId and ' +
					' (((opportunity.RecordTypeId = :rtPurchase or opportunity.RecordTypeId = :rtGift) ' + 
						' and opportunity.campaignId = :cmpIdAttendees) ' +
					' or ' +  
					' (opportunity.RecordTypeId = :rtTicket ' +
						' and opportunity.campaignId = :cmpIdTickets ' +
						' and IsPrimary=:fIncludeTicketPurchases)) ' +
					' order by contact.LastName, contact.FirstName';

			// in one soql call, get all the appropriate opportunities for auction purchases and tickets
/*			
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
*/
			for (list<OpportunityContactRole> listOCR : database.query(strSoql)) {
	       
				// now go through all the opps, and for each contact create the appropriate Receipt objects and their child opportunities.	       
		        for (OpportunityContactRole ocr : listOCR){
		        	Opportunity opp = ocr.Opportunity;
			        	
		        	// this map keeps track of whether we've already created a receipt for this contact or not.
		        	Receipt r = mapContactIdReceipt.get(ocr.contactId);
		        	if (r == null) {
		        		r = new Receipt();
		        		r.contactId = ocr.contactId;
		        		r.auctionId = auctionId;
		        		r.listOppAuctionPurchases = new list<Opportunity>();
		        		r.strContactName = ocr.Contact.Name;
		        		r.strContactFirstName = NullStr(ocr.Contact.FirstName);

		        		// use household fields instead if appropriate
						if (AUC_AuctionConstants.strContactHouseholdNameField != null) {
							list<string> listStr = AUC_AuctionConstants.strContactHouseholdNameField.split('\\.', 0);
							if (listStr.size() > 1) {
								Contact con = ocr.contact;								
								Sobject hh = con.getSobject(listStr[0]);
								string strHousehold;

								// avoid non-household accounts with household account model
								if (listStr[0] == 'Account' && 
									AUC_AuctionConstants.isNPSPHouseholdAccountModel &&
									hh.get('npe01__SYSTEM_AccountType__c') != 'Household Account') {
									hh = null;
								}
								
								if (hh != null) strHousehold = (string)hh.get(listStr[1]);
								if (strHousehold != null) r.strContactName = strHousehold;
							}
						}
						if (AUC_AuctionConstants.strContactHouseholdGreetingField != null) {
							list<string> listStr = AUC_AuctionConstants.strContactHouseholdGreetingField.split('\\.', 0);
							if (listStr.size() > 1) {
								Contact con = ocr.contact;
								Sobject hh = con.getSobject(listStr[0]);
								string strHousehold;

								// avoid non-household accounts with household account model
								if (listStr[0] == 'Account' && 
									AUC_AuctionConstants.isNPSPHouseholdAccountModel &&
									hh.get('npe01__SYSTEM_AccountType__c') != 'Household Account') {
									hh = null;
								}

								if (hh != null) strHousehold = (string)hh.get(listStr[1]);
								if (strHousehold != null) r.strContactFirstName = strHousehold;
							}
						}

		        		r.strContactAddrLine1 = NullStr(ocr.Contact.MailingStreet);
		        		r.strContactAddrLine2 = NullStr(ocr.Contact.MailingCity) + (ocr.Contact.MailingCity <> null ? ', ' : '') + 
		        			NullStr(ocr.Contact.MailingState) + '  ' + NullStr(ocr.Contact.MailingPostalCode);
		        		r.dtAuction = dtAuction;
		        		r.strBidNumber = string.valueOf(mapContactIdBidNumber.get(ocr.contactId));
		        		mapContactIdReceipt.put(r.contactId, r);
		        		listReceiptsT.add(r);
		        	}
		        	if (opp.Amount == null) opp.Amount = 0;
		        	if (opp.Auction_Non_Deductible_Amount__c == null) opp.Auction_Non_Deductible_Amount__c = 0;
	        		r.listOppAuctionPurchases.add(ocr.opportunity);
	        		r.decTotalAmountPaid += opp.Amount;
					r.decTotalAmountDeductible += opp.Auction_Deductible_Amount__c;
					r.decTotalFMV += opp.Auction_Non_Deductible_Amount__c;
		        }
	        }
	        
	        //system.debug('**** Leaving listReceipts');
	        return listReceiptsT;
	}

	// helper routine to handle null strings.
	private string NullStr(string str) {
		if (str == null) return '';
		return str;
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
			decTotalFMV = 0;
		}
		
		public ID contactId { get; set; }
		public String strContactName { get; set; }
		public String strContactFirstName { get; set; }		
		public String strContactAddrLine1 { get; set; }		
		public String strContactAddrLine2 { get; set; }		
		public ID auctionId { get; set; }
		public Date dtAuction { get; set; }
		public Decimal decTotalAmountPaid { get; set; }
		public Decimal decTotalAmountDeductible { get; set; }
		public Decimal decTotalFMV { get; set; }
		public list<Opportunity> listOppAuctionPurchases { get; set; }
		public string strBidNumber { get; set; }
		
		public String strPageTitle {
			get { 
				return UserInfo.getOrganizationName() + ' receipt for ' + strContactName;
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
		ctrl.fIncludeAllGuests = true;
		system.AssertEquals(null, ctrl.getRenderFormat());
		system.Assert(ctrl.listReceipts == null);
		system.Assert(ctrl.OpenPDF() != null);		
		system.AssertEquals('pdf', ctrl.getRenderFormat());
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
		ctrl.fIncludeAllGuests = true;
		System.AssertEquals(bigNum+1, ctrl.listReceipts.size());
		system.assert(ctrl.listReceipts2 != null);
		system.assert(ctrl.listReceipts2.size() == 0);
		system.assert(ctrl.listReceipts3 != null);
		system.assert(ctrl.listReceipts3.size() == 0);
		
		system.assertEquals(null, ctrl.strNamePurchaser);
		system.assertEquals(null, ctrl.searchPurchaser);
		ctrl.SearchPurchaserLookup();
		system.assertEquals(null, ctrl.contactIdPurchaser);
		ctrl.searchPurchaser = 'not to be found!';
		ctrl.SearchPurchaserLookup();
		system.assertEquals(null, ctrl.contactIdPurchaser);		
		ctrl.searchPurchaser = 'David Test';
		ctrl.SearchPurchaserLookup();
		system.assertEquals(false, ctrl.fIncludeAllGuests);
		system.assertEquals(contact1.id, ctrl.contactIdPurchaser);
		system.assertEquals('David Test', ctrl.strNamePurchaser);
		ctrl.ChangeIncludeTicketPurchases();
		ctrl.ChangeIncludeAllGuests();
		
		
		test.stopTest();
	}	
}