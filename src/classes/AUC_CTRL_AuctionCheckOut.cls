// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckOut {

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
			list<Contact> listCon = [select Id from Contact where Name = :searchPurchaser];
			if (listCon.size() > 0) {
				contactIdPurchaser = listCon[0].Id;
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
				strStatus = 'Enter the name or bid number of a guest, to search for their purchases.'; 
			} else if (!fPurchaser && fSearchPurchaser) {
				strStatus = 'There is no contact who attended the auction with that name.';
			} else if (fPurchaser && !fPurchases) {
				strStatus = 'This guest has no purchases from the auction.';
			} else if (fPurchaser && fPurchases) {
				strStatus = 'Check the purchases that you want to process now.';  
				if (strCreditCardChargeURL != null) {
					strStatus += ' Click <b>Charge Credit Card</b> to open a new window to pay the processor.';
				}
				strStatus += ' Click <b>Update Stages</b> to update the stage of all checked opportunities.';
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

		map<ID, CampaignMember> mapContactIdCM = new map<ID,CampaignMember>();
    	strFilter = '%' + strFilter + '%';   	
		
		// grab all contacts off the Attendees and Tickets campaign
		for (list<CampaignMember> listCM : [select contactId, contact.Name, Bid_Number__c from CampaignMember 
			where (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees or
					CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
				and contactId <> null
				and contact.Name like :strFilter
			order by contact.Name]) {
			
			for (CampaignMember cm : listCM) {				
				// if the contact isn't already in the map with a bid number, put them in.
				CampaignMember cmIn = mapContactIdCM.get(cm.contactId);
				if (cmIn == null || cmIn.Bid_Number__c == null) {
					mapContactIdCM.put(cm.contactId, cm);
				}
			}
		}
		
				
		// create our list of purchasers
		list<Purchaser> listPurchaser = new list<Purchaser>();
		for (CampaignMember cm : mapContactIdCM.values()) {
			Purchaser p = new Purchaser();
			p.contactId = cm.contactId;
			p.strName = cm.contact.Name;
			p.strBidderNumber = (cm.Bid_Number__c == null ? null : string.valueOf(integer.valueOf(cm.Bid_Number__c)));
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
				RecalcTotalAmountToPay(listReceipts);
				return listReceipts;
			}
			
			// create the list of which contacts to include
			list<ID> listContactId = new list<ID>();
			if (contactIdPurchaser != null) {
				listContactId.add(contactIdPurchaser);
			}
			// call the real worker.
			listReceipts = listReceiptsForlistContactId(listContactId);
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
				if (po.IsPayNow) {
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
		
		public String strPageTitle {
			get { 
				return UserInfo.getOrganizationName() + ' Auction receipt for ' + strContactName;
			}
		}			
	}

	// list for Stage picklist, filtered correctly for stages for Auction opps.
	public list<SelectOption> listSOStages {
		get {
			if (listSOStages == null) {
				listSOStages = new list<SelectOption>();
				
				// since we can't seem to get the styling for a required field for Stage,
				// we won't provide a blank option!
				//listSOTicketStages.add(new SelectOption('', ''));
				
				string strStages = AUC_AuctionConstants.StrTicketOpportunityStages();
				
				// if setting returns strings, use them
				if (strStages != null) {
					list<string> listStr = strStages.split(';');
					for (string  str : listStr) {
						listSOStages.add(new SelectOption(str, str));						
					}					
				} else { // otherwise use the current Salesforce Opp Stages			
					for (OpportunityStage stg : [select Id, MasterLabel from OpportunityStage where IsActive=true order by SortOrder]) {
						listSOStages.add(new SelectOption(stg.MasterLabel, stg.MasterLabel));
					}
				}
			}
			return listSOStages;
		}
		private set;
	}

	public string StageName { get; set; }
	
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
	
	// public property to get the commandButton URL
	// for the Charge Credit Card button.	
	public string strCreditCardChargeURL {
		get {
			if (strCreditCardChargeURL == null && contactIdPurchaser != null) {
				string str = AUC_AuctionConstants.StrCreditCardChargeURLFormula();
				if (str != null) {
					list<string> listFormat = new list<string>();
					listFormat.add(contactIdPurchaser);
					if (listReceipts.size() > 0) {
						listFormat.add(string.valueOf(listReceipts[0].decTotalAmountToPay));
					} else {
						listFormat.add('0');
					}
					str = string.format(str, listFormat);
				}
				strCreditCardChargeURL = str;
			}
			return strCreditCardChargeURL;
		}
		private set;
	}


	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
		
		//UNDONE: these tests haven't been updated for this page.
		return;
	}
}