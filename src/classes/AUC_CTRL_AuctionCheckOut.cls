// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckOut {

	// constructor
	public AUC_CTRL_AuctionCheckOut() {
		
		// force IE into Standards Mode
		ApexPages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		 		
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

	// private status String for reporting the results of saving.
    @TestVisible private String strSaveResults { get; set; }
    
	// helper routine to return all Opportunity field names
	private String strOppFields {
		get {
			if (strOppFields == null) {				
				// initialize the list of all fields on Opportunity.
				// we could have just queried the field set, but our page also looks at
				// multiple other Opp fields, so it is easiest to just get them all.
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Opportunity.fields.getMap();
				List<String> listStrFields = new List<String>();
				listStrFields.addAll(mapS.keySet());  
				strOppFields = '';
				for (String str : listStrFields) {
					strOppFields += 'Opportunity.' + str + ',';
				}  		
				strOppFields = strOppFields.substring(0, strOppFields.length()-1);
			}
			return strOppFields;
		}
		set;
	}    
	
 	// the currently selected Auction 
	public Id auctionId { get; set; }
	
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions { get; set; }
	 
	// action method called when the auction dropdown is changed.	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		listReceipts = null;
		contactIdPurchaser = null;
		strSaveResults = null;
		return null;
	}

	// holds the currently selected Purchaser contact
	// has to be a String to allow a null Id ('') to get returned from the page.
	public String contactIdPurchaser { 
		get; 
		set {
			// first invalidate anything dependent on a change
			if (contactIdPurchaser != value) {
				strNamePurchaser = null;
				strBidderNumber = null;
				listReceipts = null;
				strCreditCardChargeURL = null;
				strOpenReceiptURL = null;
				fShowPanelCreditCard = false;
				strPaymentMethod = null;
				strCheckNumber = null;
				fOppsToUpdate = false;
			}
			contactIdPurchaser = value;
			if (contactIdPurchaser == '') contactIdPurchaser = null; 
		}		
	}
	
	// holds the currently selected Purchaser's name (and bid number)	
	public String strNamePurchaser { 
		get {
			if (strNamePurchaser == null && contactIdPurchaser != null) {
				Contact con = [SELECT Name FROM Contact WHERE Id = :contactIdPurchaser];
				strNamePurchaser = con.Name;
				if (strBidderNumber != null) strNamePurchaser += ' - ' + strBidderNumber; 
			}
			return strNamePurchaser;
		}
		private set;
	}
	
	private String strBidderNumber {
		get {
			if (strBidderNumber == null && contactIdPurchaser != null) {				
				List<CampaignMember> listCm = [SELECT ContactId, Bid_Number__c FROM CampaignMember
					WHERE (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees OR
					CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
					AND ContactId = :contactIdPurchaser];
				if (listCm.size() > 0 ) {
					strBidderNumber = (listCm[0].Bid_Number__c == null ? '' : String.valueOf(Integer.valueOf(listCm[0].Bid_Number__c)));
				}
			}
			return strBidderNumber;
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
	
	// this parameter is used in scenarios WHERE the page
	// needs us to search for an Purchaser before it could wait
	// for the return from its javascript remoting call to get data
	public String searchPurchaser { get; set; }
	
	// callback when the user changes the Attendee contact lookup and submits too quick.
	public PageReference SearchPurchaserLookup() {
		if (searchPurchaser != null && searchPurchaser != '') {

			// need to search by both contact name and bid number
			Decimal decBid = -1;
			try {
				decBid = Decimal.valueOf(searchPurchaser);
			} catch (Exception ex) {}
			List<CampaignMember> listCM = [SELECT ContactId, Contact.Name, Bid_Number__c FROM CampaignMember
				WHERE (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees OR
						CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
					AND ContactId <> NULL
					AND (Contact.Name = :searchPurchaser OR Bid_Number__c = :decBid)];
			if (listCM.size() > 0) {
				contactIdPurchaser = listCM[0].ContactId;
			} else {
				contactIdPurchaser = null;
				strSaveResults = null;
				strNamePurchaser = searchPurchaser; // to keep displaying the text.
				return null;
			}
		} else {
			contactIdPurchaser = null;	
			strNamePurchaser = null;	
			strBidderNumber = null;	
		}
		return ChangePurchaserLookup();
	}

	// status String for reporting helpful instructions and the results of saving.
	public String strStatus {
		
		get {
			Boolean fPurchaser = contactIdPurchaser != null && contactIdPurchaser != '';
			Boolean fSearchPurchaser = searchPurchaser != null && searchPurchaser != '';
			Boolean fPurchases = listReceipts.size() > 0 && 
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
				strStatus = '1. Check <b>Pay Now</b> for the purchases you wish to process.';  
				strStatus += '<br/>2. Choose the Payment Method.';
				if (strCreditCardChargeURL != null) {				
					  strStatus += '&nbsp;&nbsp;<b>Credit Card</b> will open a new ' + (fShowPaymentProcessorOnPage ? 'panel' : 'window') + ' to process the charge.';
				}
				strStatus += '<br/>3. Click <b>Update Opportunities</b> to complete processing.';
				strStatus += '<br/>4. Continue with next steps.';
			}
			return strStatus;
		}
		private set;
	}
	
	// Boolean to track when the purchaser's opportunities need to be updated
	public Boolean fOppsToUpdate { get; set; }

	//==================== Purchaser Class ======================================
	// helper class that holds a contact, and their bid number
	global class Purchaser {		
		global Purchaser() {}		
		global Id contactId { get; set; }
		global String strBidderNumber { get; set; }
		global String strName { get; set; }		
	}

	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts who purchased Auction Items
	* or Auction Tickets on the specified auction, optionally filtered by strFilter.
	* @param auctionId the Auction to filter by 
	* @param strFilter the subString to filter by 
	* @return List<Purchaser>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static List<Purchaser> getListPurchasers(String auctionId, String strFilter) {
	    UTIL_Describe.checkObjectReadAccess('Contact');
	    UTIL_Describe.checkObjectReadAccess('CampaignMember');
		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;

		// hold a map from contact ID's to their Campaign Members.
		Map<Id, CampaignMember> mapContactIdCM = new Map<Id,CampaignMember>();
		
		// this list will hold the same contactID's, but in their sorted order, so we can
		// return an alphabetized list.
		List<Id> listContactId = new List<Id>();
		
    	strFilter = '%' + strFilter + '%';   	
		
		// grab all contacts off the Attendees and Tickets campaign
		for (List<CampaignMember> listCM : [SELECT ContactId, Contact.Name, Bid_Number__c FROM CampaignMember
			WHERE (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees OR
					CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
				AND ContactId <> NULL
				AND Contact.Name LIKE :strFilter
				AND Status <> 'RSVP No'
			ORDER BY Contact.LastName, Contact.FirstName]) {
			
			for (CampaignMember cm : listCM) {				
				// if the contact isn't already in the map with a bid number, put them in.
				CampaignMember cmIn = mapContactIdCM.get(cm.ContactId);
				if (cmIn == null || (cmIn.Bid_Number__c == null && cm.Bid_Number__c != null)) {
					mapContactIdCM.put(cm.ContactId, cm);
					// only add them to this list once
					if (cmIn == null) listContactId.add(cm.ContactId);
				}
			}
		}
						
		// create our list of purchasers
		List<Purchaser> listPurchaser = new List<Purchaser>();
		for (Id conId : listContactId) {
			CampaignMember cm = mapContactIdCM.get(conId);
			Purchaser p = new Purchaser();
			p.contactId = cm.ContactId;
			p.strName = cm.Contact.Name;
			p.strBidderNumber = (cm.Bid_Number__c == null ? '' : String.valueOf(Integer.valueOf(cm.Bid_Number__c)));
			listPurchaser.add(p);
		}
		return listPurchaser; 
    } 	
    
	// are there any purchase opportunities to display?
	public Boolean fHasReceipts {
		get {
			if (listReceipts == null) return false;
			if (listReceipts.size() == 0) return false;
			return true;
		}
	}
	
	// list of Receipt objects to display
	public List<Receipt> listReceipts {
		get {
			if (listReceipts != null) {
				return listReceipts;
			}
			
			// create the list of which contacts to include
			List<Id> listContactId = new List<Id>();
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
	// CheckOut doesn't need to handle multiple contacts, but we copied this from AuctionsReceipts which does.
	private List<Receipt> listReceiptsForlistContactId(List<Id> listContactId) {
		try {
			UTIL_Describe.checkObjectReadAccess('Contact');
			UTIL_Describe.checkObjectReadAccess('Opportunity');

			List<Receipt> listReceiptsT = new List<Receipt>();
			Date dtAuction = AUC_AuctionMaintenance.DateOfAuctionId(auctionId);
			Map<Id, Receipt> mapContactIdReceipt = new Map<Id, Receipt>();
			String rtPurchase = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem;
			String rtGift = AUC_AuctionMaintenance.recordtypeIdAuctionGift;
			String rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
			String cmpIdAttendees = auctionMaintenance.campaignIdAuctionAttendees;
			String cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;

			String strSoql = 'SELECT contactId, contact.Name, contact.FirstName, contact.MailingStreet, contact.MailingCity, contact.MailingState, contact.MailingPostalCode, ' +
				' opportunity.RecordType.Name, ' + AUC_AuctionMaintenance.StrEscape(strOppFields) +
				' FROM OpportunityContactRole ' +
				' WHERE IsPrimary=true AND contactId in :listContactId AND ' +
				' (((opportunity.RecordTypeId = :rtPurchase OR opportunity.RecordTypeId = :rtGift) ' +
				' AND opportunity.campaignId = :cmpIdAttendees) ' +
				' OR ' +
				' (opportunity.RecordTypeId = :rtTicket ' +
				' AND opportunity.campaignId = :cmpIdTickets ' +
				' AND IsPrimary=true)) ' +
				' order by contact.LastName, contact.FirstName';

/*			
			// in one soql call, get all the appropriate opportunities for auction purchases and tickets
			for (List<OpportunityContactRole> listOCR : [SELECT contactId, contact.Name, contact.FirstName, opportunityId, opportunity.Id, 
				opportunity.name, opportunity.Amount, opportunity.Auction_Item_Name__c, opportunity.Auction_Deductible_Amount__c, 				
				opportunity.IsWon, opportunity.RecordTypeId, opportunity.StageName, opportunity.IsClosed,
				opportunity.RecordType.Name, opportunity.Description FROM OpportunityContactRole 
				WHERE IsPrimary=true AND contactId in :listContactId and
					(((opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem OR opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionGift) 
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionAttendees)
					or 
					(opportunity.RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionTicket
						and opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets
						and IsPrimary=true)) 
				order by contact.Name]) {
*/
			for (List<OpportunityContactRole> listOCR : Database.query(strSoql)) {


				// now go through all the opps, and for each contact create the appropriate Receipt objects and their child opportunities.	       
				for (OpportunityContactRole ocr : listOCR) {
					Opportunity opp = ocr.Opportunity;

					//System.debug('DUMPING OCR Info ------------------------------------------------------');
					//System.debug(ocr.ContactId);
					//System.debug(ocr.opportunity.name);
					//System.debug(ocr.opportunity.amount);
					//System.debug(ocr.opportunity.Auction_Item_Name__c);
					//System.debug(opp.name);

					// this map keeps track of whether we've already created a receipt for this contact or not.
					Receipt r = mapContactIdReceipt.get(ocr.ContactId);
					if (r == null) {
						r = new Receipt();
						r.contactId = ocr.ContactId;
						r.auctionId = auctionId;
						r.listOppAuctionPurchases = new List<AUC_PurchaseOpportunity>();
						r.strContactName = ocr.Contact.Name;
						r.strContactFirstName = ocr.Contact.FirstName;
						r.dtAuction = dtAuction;
						mapContactIdReceipt.put(r.contactId, r);
						listReceiptsT.add(r);
					}
					AUC_PurchaseOpportunity po = new AUC_PurchaseOpportunity(ocr.Opportunity);
					r.listOppAuctionPurchases.add(po);
					if (opp.Amount <> null) {
						r.decTotalAmountPaid += opp.Amount;
						if (po.IsPayNow) {
							r.decTotalAmountToPay += opp.Amount;
							fOppsToUpdate = true;
						}
					}
					//r.decTotalAmountDeductible += opp.Auction_Deductible_Amount__c;
					//if (opp.IsWon) r.decTotalAmountReceived += opp.Amount;
				}
			}

			//System.debug('**** Leaving listReceipts');
			return listReceiptsT;
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
			return new List<Receipt>();
		}
	}
	
	// utility to go through all receipts, and retotal how much they plan to pay.
	private void RecalcTotalAmountToPay(List<Receipt> listR) {
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
			
	// utility to count how many opps are checked.
	private Integer CountCheckOpps(List<Receipt> listR) {
		if (listR == null) return 0;
		Integer cnt = 0;
		for (Receipt r : listR) {
			for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
				if (po.IsPayNow) {
					cnt++;
				}
			}
		}
		return cnt;
	}

	//==================== Receipt Class ======================================
	// helper class that holds a contact, and their opportunities
	// the VF Page will iterate through a list of these that the controller provides.
	public class Receipt {
		
		// constructor
		public Receipt() {
			//System.debug('**** Creating Receipt');
			decTotalAmountPaid = 0;
			//decTotalAmountDeductible = 0;	
			//decTotalAmountReceived = 0;
			decTotalAmountToPay = 0;
		}
		
		public Id contactId { get; set; }
		public String strContactName { get; set; }
		public String strContactFirstName { get; set; }		
		public Id auctionId { get; set; }
		public Date dtAuction { get; set; }
		public Decimal decTotalAmountPaid { get; set; }
		public Decimal decTotalAmountToPay { get; set; }
		//public Decimal decTotalAmountDeductible { get; set; }
		//public Decimal decTotalAmountReceived { get; set; }
		public List<AUC_PurchaseOpportunity> listOppAuctionPurchases { get; set; }
		
	}

	// action method called by page whenever a paynow checkbox is changed.
	// recalc totals to pay.
	public PageReference ChangePayNow() {
		strSaveResults = null;
		RecalcTotalAmountToPay(listReceipts);	
		fOppsToUpdate = true;
		return null;				
	}
	
	// parameter for ChangePayNow action method, set by page
	public Id oppIdChecked { get; set; }
	
	// public method to update all checked opportunities to
	// the paid StageName, and to update Payment Method and potentially Check Number on
	// either custom fields (specified in AuctionSettings), or on the Payment Object of the NPSP.
	public PageReference UpdateCheckedOpps() {
		Savepoint sp = Database.setSavepoint();
		try {
			UTIL_Describe.checkObjectUpdateAccess('Opportunity');
			strSaveResults = null;
			
			if (CountCheckOpps(listReceipts) == 0) {
				strSaveResults = 'You must Check off which Opportunities to update.';
				return null;
			}
			
			fShowPanelCreditCard = false;
			
			List<Opportunity> listOppToUpdate = new List<Opportunity>();
	
			for (Receipt r : listReceipts) {
				for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
					if (po.IsPayNow) {
						AUC_AuctionMaintenance.setOpportunityStageClosed(po.opp);
						listOppToUpdate.add(po.opp);
						po.IsPayNow = false;
						if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
							po.opp.put(AUC_AuctionConstants.strOppPaymentMethodField, strPaymentMethod);
						}
						if (AUC_AuctionConstants.strOppCheckNumberField != null && strPaymentMethod == 'Check') {
							po.opp.put(AUC_AuctionConstants.strOppCheckNumberField, strCheckNumber);
						}					
					}
				}
			}
			
			// save the new stages
			update listOppToUpdate;
			
			// if using NPSP Payments, update payment info.
			AUC_AuctionMaintenance.UpdateNPSPPayments(listOppToUpdate, strPaymentMethod, strCheckNumber);
			
			// force the totals to recalc
			//RecalcTotalAmountToPay(listReceipts);
			// now force full reload to get all Opp fields updated
			listReceipts = null;	
			
			// clear our flag
			fOppsToUpdate = false;
			return null;
	    } catch (Exception e) {
			Database.rollback(sp);
			ApexPages.addMessages(e);
	        return null;
	    } 
   	}

	// public method for the Next Guest button.  
	// clear out guest, and refresh the page.
	public PageReference NextGuest() {
		contactIdPurchaser = null;
		// force IE into Standards Mode
		ApexPages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		return null;
	}
		
	// public method for the Close button.  
	// use retURL if we have it, otherwise go to tickets tab.
	public PageReference Close() {
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if (retURL == null || retURL == '') {
			retURL = '/apex/GW_Auctions__AuctionPurchases';
		}
		PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
	}
	
	// public property of the total amount checked off to pay.
	public Decimal decTotalAmountToPay {
		get {
			if (listReceipts != null && listReceipts.size() > 0) {
				return listReceipts[0].decTotalAmountToPay;
			} else {
				return 0;
			}			
		}
		private set;
	}
	
	public String strPaymentMethod { get; set; }
	public String strCheckNumber { get; set; }
	
	// public method called by the page when the Payment Method changes
	public PageReference ChangePaymentMethod() {
		// new value will be in strPaymentMethod
		fShowPanelCreditCard = false;
		return null;
	}
	
	// public property to get the commandButton URL
	// for the Charge Credit Card button.	
	public String strCreditCardChargeURL {
		get {
			if (strCreditCardChargeURL == null && contactIdPurchaser != null) {
				String str = AUC_AuctionConstants.StrCreditCardChargeURLFormula();
				if (str != null) {
					// {0} = contactId
					// {1} = auctionId
					// {2} = amount		
					// {3} = sessionId
					// {4} = partner server url
					// {5} = organizationId
					// {6} = comma separated list of OppId's
					List<String> listFormat = new List<String>();
					listFormat.add(contactIdPurchaser);
					listFormat.add(auctionId);
					if (listReceipts.size() > 0) {
						listFormat.add(String.valueOf(listReceipts[0].decTotalAmountToPay));
					} else {
						listFormat.add('0');
					}
					listFormat.add(UserInfo.getSessionId());
					String strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
					listFormat.add(strServerURL);					
					listFormat.add(UserInfo.getOrganizationId());
                    listFormat.add(String.join(getOppIdsToPay(), ','));
					str = String.format(str, listFormat);
				}
				strCreditCardChargeURL = str;
			}
			return strCreditCardChargeURL;
		}
		private set;
	}

    // returns a list of OppId's for those Opportunities marked to be paid
    @TestVisible private List<Id> getOppIdsToPay() {
        List<Id> listId = new List<Id>();

        for (Receipt r : listReceipts) {
            for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
                if (po.IsPayNow) {
                    listId.add(po.opp.Id);
                }
            }
        }
        return listId;
    }
		
	// public property for the Window.Open() parameters
	// for the virtual terminal window.
	public String strPaymentProcessorWindowParameters {
		get {
			return AUC_AuctionConstants.StrPaymentProcessorWindowParameters();
		}
	}
	
	// public property for whether to display the payment
	// processor's virtual terminal on our page, or in a new browser window.
	public Boolean fShowPaymentProcessorOnPage {
		get {
			return AUC_AuctionConstants.fShowPaymentProcessorOnPage;
		}
	}	

	// public property for the IFRAME Height parameter
	// for the virtual terminal window if displaying on our page.
	public String strPaymentProcessorPageHeight {
		get {
			return AUC_AuctionConstants.StrPaymentProcessorPageHeight();
		}
	}

	// the following two properties are set in the constructor by passed in page parameters,
	// so that this page can get the correct sessionId of the 'front-end' server that
	// Conga merge requires to use Salesforce reports as a data source!
	// Unfortunately, we still couldn't get the correct Session from parameters
	// to a Check Out web tab, so I have removed this functionality.
	// private String strApiSessionId { get; set; }
	// private String strApiPartnerServerURL { get; set; }

	// public property to get the commandButton URL
	// for the View button, to invoke the receipts page  
	public String strOpenReceiptURL {
		get {
		
		/*******
			String str = AUC_AuctionConstants.StrCheckOutReceiptsURLFormula();
			if (str != null) {
				// {0} = contactId
				// {1} = auctionId
				// {2} = amount		
				// {3} = sessionId
				// {4} = partner server url
				// {5} = organizationId
				
				// NOTE that Conga wants 15 character ID's not 18.
				
				List<String> listFormat = new List<String>();
				String strID = contactIdPurchaser;
				listFormat.add(strID.left(15));
				strID = auctionId;
				listFormat.add(strID.left(15));
				if (listReceipts.size() > 0) {
					listFormat.add(string.valueOf(listReceipts[0].decTotalAmountToPay));
				} else {
					listFormat.add('0');
				}
				// get the correct session Id that works with Conga.
				//listFormat.add(EncodingUtil.urlEncode(UserInfo.getSessionId(),'UTF-8'));
				listFormat.add(EncodingUtil.urlEncode(strApiSessionId,'UTF-8'));

				// use the partner server URL that works with Conga.				
				//String strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
				listFormat.add(EncodingUtil.urlEncode(strApiPartnerServerURL,'UTF-8'));					
				
				// Conga won't use this, but in case a future use case comes up.
				listFormat.add(UserInfo.getOrganizationId());					
				str = string.format(str, listFormat);	
				return str;		
			} else {	
		*********/
			{		
				return '/apex/GW_Auctions__AuctionReceipts' +
		        	'?RenderFormat=pdf' +
		        	'&auctionId=' + auctionId +
		        	'&contactId=' + contactIdPurchaser +
		        	'&IncludeTickets=true';
			}
		}
		private set;
	}
	
	// public property on whether to display the credit card panel
	public Boolean fShowPanelCreditCard { get; set; }
	
	// public method to show the credit card panel
	public PageReference ShowPanelCreditCard() {
		fShowPanelCreditCard = true;
		strPaymentMethod = 'Credit Card';
		return null;
	}

	// property to tell whether there is no place to store the Payment Method 
	public Boolean isPaymentSettingsMissing {
		get {
			return AUC_AuctionConstants.isPaymentSettingsMissing;
		}
	}
}