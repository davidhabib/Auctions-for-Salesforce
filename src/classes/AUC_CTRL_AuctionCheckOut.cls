// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckOut {

	// constructor
	public AUC_CTRL_AuctionCheckOut() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;	
		} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = listSOAuctions[1].getValue();
		}
		auctionMaintenance.auctionId = auctionId;	

		// handle the no auction case
		if (auctionId == null) {
			strSaveResults = 'You must first create an Auction before using this page.';
		}				
	}

	private AUC_AuctionMaintenance auctionMaintenance;

	// private status string for reporting the results of saving.
    private String strSaveResults { get; set; } 
	
 	// the currently selected Auction 
	public Id auctionId { get; set; }
	
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }
	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		listReceipts = null;
		contactIdPurchaser = null;
		strSaveResults = null;
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
				strCreditCardChargeURL = null;
				strOpenReceiptURL = null;
				fShowPanelCreditCard = false;
			}
			contactIdPurchaser = value;
			if (contactIdPurchaser == '') contactIdPurchaser = null; 
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
		strSaveResults = null;
		
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
				strSaveResults = null;
				strNamePurchaser = searchPurchaser; // to keep displaying the text.
				return null;
			}
		} else {
			contactIdPurchaser = null;	
			strNamePurchaser = null;		
		}
		return ChangePurchaserLookup();
	}

	// status string for reporting helpful instructions and the results of saving.
	public string strStatus {
		
		get {
			boolean fPurchaser = contactIdPurchaser != null && contactIdPurchaser != '';
			boolean fSearchPurchaser = searchPurchaser != null && searchPurchaser != '';
			boolean fPurchases = listReceipts.size() > 0 && 
				listReceipts[0].listOppAuctionPurchases.size() > 0;
			
			if (strSaveResults != null) {
				strStatus = strSaveResults;
			} else if (!fPurchaser && !fSearchPurchaser) {
				strStatus = 'Enter the name or bid number of a guest to display purchases.'; 
			} else if (!fPurchaser && fSearchPurchaser) {
				strStatus = 'No attendee found by that name for the selected auction.';
			} else if (fPurchaser && !fPurchases) {
				strStatus = 'Guest has no purchases entered for the selected auction.';
			} else if (fPurchaser && fPurchases) {
				strStatus = 'Check <b>Pay Now</b> for the purchases you wish to process.';  
				//if (strCreditCardChargeURL != null) {
					strStatus += ' Click <b>Charge Credit Card</b> to open a new window to process payment.';
				//}
				strStatus += ' Select the appropriate stage value and click <b>Update</b> to complete processing.';
			}
			return strStatus;
		}
		private set;
	}

	//==================== Purchaser Class ======================================
	// helper class that holds a contact, and their bid number
	global class Purchaser {		
		global Purchaser() {}		
		global ID contactId { get; set; }
		global string strBidderNumber { get; set; }
		global string strName { get; set; }		
	}

	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts who purchased Auction Items
	* or Auction Tickets on the specified auction, optionally filtered by strFilter.
	* @param auctionId the Auction to filter by 
	* @param strFilter the substring to filter by 
	* @return list<Purchaser>, which will be turned into a Javascript collection.
	********************************************************************************************************/
   @RemoteAction global static list<Purchaser> getListPurchasers(string auctionId, string strFilter) {
		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;

		// hold a map from contact ID's to their Campaign Members.
		map<ID, CampaignMember> mapContactIdCM = new map<ID,CampaignMember>();
		
		// this list will hold the same contactID's, but in their sorted order, so we can
		// return an alphabetized list.
		list<ID> listContactId = new list<ID>();
		
    	strFilter = '%' + strFilter + '%';   	
		
		// grab all contacts off the Attendees and Tickets campaign
		for (list<CampaignMember> listCM : [select contactId, contact.Name, Bid_Number__c from CampaignMember 
			where (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees or
					CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
				and contactId <> null
				and contact.Name like :strFilter
				and Status <> 'RSVP No'
			order by contact.LastName, contact.FirstName]) {
			
			for (CampaignMember cm : listCM) {				
				// if the contact isn't already in the map with a bid number, put them in.
				CampaignMember cmIn = mapContactIdCM.get(cm.contactId);
				if (cmIn == null || (cmIn.Bid_Number__c == null && cm.Bid_Number__c != null)) {
					mapContactIdCM.put(cm.contactId, cm);
					// only add them to this list once
					if (cmIn == null) listContactId.add(cm.contactId);
				}
			}
		}
						
		// create our list of purchasers
		list<Purchaser> listPurchaser = new list<Purchaser>();
		for (ID conId : listContactId) {
			CampaignMember cm = mapContactIdCM.get(conId);
			Purchaser p = new Purchaser();
			p.contactId = cm.contactId;
			p.strName = cm.contact.Name;
			p.strBidderNumber = (cm.Bid_Number__c == null ? '' : string.valueOf(integer.valueOf(cm.Bid_Number__c)));
			listPurchaser.add(p);
		}
		return listPurchaser; 
    } 	
    
	public Boolean fHasReceipts {
		get {
			if (listReceipts == null) return False;
			if (listReceipts.size() == 0) return False;
			return True;
		}
	}
	
	// list of Receipt objects to display
	public list<Receipt> listReceipts {
		get {
			if (listReceipts != null) {
				return listReceipts;
			}
			
			// create the list of which contacts to include
			list<ID> listContactId = new list<ID>();
			if (contactIdPurchaser != null) {
				listContactId.add(contactIdPurchaser);
			}
			// call the real worker.
			listReceipts = listReceiptsForlistContactId(listContactId);
			// force the totals to recalc
			RecalcTotalAmountToPay(listReceipts);					
			return listReceipts;
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
				opportunity.IsWon, opportunity.RecordTypeId, opportunity.StageName, opportunity.IsClosed,
				opportunity.RecordType.Name, opportunity.Description from OpportunityContactRole 
				where IsPrimary=true and contactId in :listContactId and
					(((opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem or opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionGift) 
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionAttendees)
					or 
					(opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionTicket
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets
						and IsPrimary=true)) 
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
		        	AUC_PurchaseOpportunity po = new AUC_PurchaseOpportunity(ocr.opportunity);
	        		r.listOppAuctionPurchases.add(po);
	        		if (opp.Amount <> null) {
	        			r.decTotalAmountPaid += opp.Amount;
	        			if (po.IsPayNow) {
	        				r.decTotalAmountToPay += opp.Amount;
	        			}
	        		}
					//r.decTotalAmountDeductible += opp.Auction_Deductible_Amount__c;
					//if (opp.IsWon) r.decTotalAmountReceived += opp.Amount;
		        }
	        }
	        
	        //system.debug('**** Leaving listReceipts');
	        return listReceiptsT;
	}
	
	// utility to go through all receipts, and retotal how much they plan to pay.
	private void RecalcTotalAmountToPay(list<Receipt> listR) {
		if (listR == null) return;
		
		for (Receipt r : listR) {
			r.decTotalAmountToPay = 0;
			for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
				if (po.IsPayNow && po.opp.Amount != null) {
					r.decTotalAmountToPay += po.opp.Amount;
				}
			}
		}
		// force this url to get refreshed with the new amount.
		strCreditCardChargeURL = null;
	}
			
	//==================== Receipt Class ======================================
	// helper class that holds a contact, and their opportunities
	// the VF Page will iterate through a list of these that the controller provides.
	public class Receipt {
		
		// constructor
		public Receipt() {
			//system.debug('**** Creating Receipt');
			decTotalAmountPaid = 0;
			//decTotalAmountDeductible = 0;	
			//decTotalAmountReceived = 0;
			decTotalAmountToPay = 0;
		}
		
		public ID contactId { get; set; }
		public String strContactName { get; set; }
		public String strContactFirstName { get; set; }		
		public ID auctionId { get; set; }
		public Date dtAuction { get; set; }
		public Decimal decTotalAmountPaid { get; set; }
		public Decimal decTotalAmountToPay { get; set; }
		//public Decimal decTotalAmountDeductible { get; set; }
		//public Decimal decTotalAmountReceived { get; set; }
		public list<AUC_PurchaseOpportunity> listOppAuctionPurchases { get; set; }
		
	}

	// action method called by page whenever a paynow checkbox is changed.
	public PageReference ChangePayNow() {
		strSaveResults = null;
		RecalcTotalAmountToPay(listReceipts);	
		return null;				
	}
	
	// used to specify the new stage for the UpdateOppStages() action method.
	public Opportunity oppForStage {
		get {
			if (oppForStage == null) {
				oppForStage = new Opportunity(recordtypeId=AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem);
			}
			return oppForStage;
		}
		private set;
	}
	
	// public method to update all checked opportunities to 
	// the new stage specified in StageName.
	public PageReference UpdateOppStages() {
		strSaveResults = null;
		fShowPanelCreditCard = false;
		if (listReceipts == null || oppForStage.StageName == '' || oppForStage.StageName == null) {
			strSaveResults = 'Please specify the new ' + Schema.SObjectType.Opportunity.fields.StageName.label + ' to set.';
			return null;
		}
			    	
		list<Opportunity> listOppToUpdate = new list<Opportunity>();

		for (Receipt r : listReceipts) {
			for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
				if (po.IsPayNow) {
					po.opp.StageName = oppForStage.StageName;
					listOppToUpdate.add(po.opp);
					// turn off PayNow
					po.IsPayNow = false;
				}
			}
		}
		
		// save the new stages
		update listOppToUpdate;
		
		// force the totals to recalc
		RecalcTotalAmountToPay(listReceipts);
		
		return null;
	}

	// public method for the Next Guest button.  
	// clear out guest, and refresh the page.
	public PageReference NextGuest() {
		contactIdPurchaser = null;
		return null;
	}
		
	// public method for the Close button.  
	// use retURL if we have it, otherwise go to tickets tab.
	public PageReference Close() {
		string retURL = ApexPages.currentPage().getParameters().get('retURL');
		if (retURL == null || retURL == '') {
			retURL = '/apex/GW_Auctions__AuctionPurchases';
		}
		PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
	}
	
	// public property of the total amount checked off to pay.
	public decimal decTotalAmountToPay {
		get {
			if (listReceipts != null && listReceipts.size() > 0) {
				return listReceipts[0].decTotalAmountToPay;
			} else {
				return 0;
			}			
		}
		private set;
	}
	
	// public property to get the commandButton URL
	// for the Charge Credit Card button.	
	public string strCreditCardChargeURL {
		get {
			if (strCreditCardChargeURL == null && contactIdPurchaser != null) {
				string str = AUC_AuctionConstants.StrCreditCardChargeURLFormula();
				if (str != null) {
					// {0} = contactId
					// {1} = auctionId
					// {2} = amount		
					// {3} = sessionId
					// {4} = partner server url
					// {5} = organizationId
					list<string> listFormat = new list<string>();
					listFormat.add(contactIdPurchaser);
					listFormat.add(auctionId);
					if (listReceipts.size() > 0) {
						listFormat.add(string.valueOf(listReceipts[0].decTotalAmountToPay));
					} else {
						listFormat.add('0');
					}
					listFormat.add(UserInfo.getSessionId());
					string strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
					listFormat.add(strServerURL);					
					listFormat.add(UserInfo.getOrganizationId());					
					str = string.format(str, listFormat);			
				}
				strCreditCardChargeURL = str;
			}
			return strCreditCardChargeURL;
		}
		private set;
	}
	
	// public property for the Window.Open() parameters
	// for the virtual terminal window.
	public string strPaymentProcessorWindowParameters {
		get {
			return AUC_AuctionConstants.StrPaymentProcessorWindowParameters();
		}
	}
	
	// public property for whether to display the payment
	// processor's virtual terminal on our page, or in a new browser window.
	public boolean fShowPaymentProcessorOnPage {
		get {
			return AUC_AuctionConstants.fShowPaymentProcessorOnPage;
		}
	}	

	// public property for the IFRAME Height parameter
	// for the virtual terminal window if displaying on our page.
	public string strPaymentProcessorPageHeight {
		get {
			return AUC_AuctionConstants.StrPaymentProcessorPageHeight();
		}
	}

	// public property to get the commandButton URL
	// for the View button, to invoke the receipts page  
	public string strOpenReceiptURL {
		get {
			return '/apex/GW_Auctions__AuctionReceipts' +
	        	'?RenderFormat=pdf' +
	        	'&auctionId=' + auctionId +
	        	'&contactId=' + contactIdPurchaser +
	        	'&IncludeTickets=true';
		}
		private set;
	}
	
	// public property on whether to display the credit card panel
	public boolean fShowPanelCreditCard { get; set; }
	
	// public method to show the credit card panel
	public PageReference ShowPanelCreditCard() {
		fShowPanelCreditCard = true;
		return null;
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
    		StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED,
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
		
		ctrl.searchPurchaser = '';
		ctrl.SearchPurchaserLookup();
		system.assertEquals(null, ctrl.contactIdPurchaser);
		system.assert(ctrl.strStatus.startsWith('Enter the name'));

		ctrl.searchPurchaser = 'This guy does not exist';
		ctrl.SearchPurchaserLookup();
		system.assertEquals(null, ctrl.contactIdPurchaser);
		system.assert(ctrl.strStatus.startsWith('No attendee'));

		ctrl.searchPurchaser = 'David Test';
		ctrl.SearchPurchaserLookup();
		system.assertEquals(contact1.id, ctrl.contactIdPurchaser);
		system.assertEquals('David Test', ctrl.strNamePurchaser);
		system.assert(ctrl.strStatus.startsWith('Check <b>Pay Now</b>'));
		system.assert(ctrl.listReceipts != null);
		system.assertEquals(1, ctrl.listReceipts.size());
		system.assert(ctrl.listReceipts[0].listOppAuctionPurchases != null);
		system.assertEquals(1, ctrl.listReceipts[0].listOppAuctionPurchases.size());
		system.assertEquals(150, ctrl.listReceipts[0].decTotalAmountToPay);
		system.assert(ctrl.strOpenReceiptURL != null);
		system.assert(ctrl.strCreditCardChargeURL == null || ctrl.strCreditCardChargeURL != null);
		system.Assert(ctrl.fHasReceipts);
		system.assertEquals(null, ctrl.ChangePayNow()); 

		opp = [select Id, Name, Auction_Deductible_Amount__c, StageName from Opportunity where Id=:oppPurchase.id];
    	system.AssertEquals(AUC_AuctionConstants.OPP_STAGE_PLEDGED, opp.StageName);
		system.assert(ctrl.UpdateOppStages() == null);
		ctrl.oppForStage.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;
		system.assert(ctrl.UpdateOppStages() == null);
		opp = [select Id, Name, Auction_Deductible_Amount__c, StageName from Opportunity where Id=:oppPurchase.id];
    	system.AssertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, opp.StageName);
		
		list<Purchaser> listP = getListPurchasers(auction.Id, 'Test');
		system.assert(listP != null);
		system.assertEquals(2, listP.size());
		
		ctrl.contactIdPurchaser = contact2.id;
		ctrl.ChangePurchaserLookup();
		system.assert(ctrl.strStatus.contains('no purchases'));
		system.Assert(ctrl.listReceipts != null);
		system.Assert(ctrl.listReceipts.size() == 0); // since contact2 has no purchases.
		system.Assert(ctrl.fHasReceipts == false);
		system.assert(ctrl.close() != null);
		
	}	

}