// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionReceipts {

	// constructor
	public AUC_CTRL_AuctionReceipts() {
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

		// default state
		fIncludeTicketPurchases = false;
		fIncludeAllGuests = false;
		fAddressToHousehold = true;
		contactIdPurchaser = null;

		Map<String, String> mapParams = ApexPages.currentPage().getParameters();

		// also support a specific contact (to allow page to be invoked on a specific receipt)
		String strcontactId = AUC_AuctionMaintenance.StrEscape(mapParams.get('contactId'));
		if (strcontactId != null && strcontactId != '') {
			contactIdPurchaser = strcontactId;
		}

		// IncludeAll parameter 
		String fAll = AUC_AuctionMaintenance.StrEscape(mapParams.get('IncludeAll'));
		if (fAll != null && fAll == 'true') {
			fIncludeAllGuests = true;
		}

		// IncludeTickets parameter 
		String fTickets = AUC_AuctionMaintenance.StrEscape(mapParams.get('IncludeTickets'));
		if (fTickets != null && fTickets == 'true') {
			fIncludeTicketPurchases = true;
		}

		// AddressToHousehold parameter
		String fHH = AUC_AuctionMaintenance.StrEscape(mapParams.get('AddressToHousehold'));
		if (fHH != null && fHH == 'false') {
			fAddressToHousehold = false;
		}

		getRenderFormat();

		doFLSChecks();
	}

	public void doFLSChecks() {
		try {
			UTIL_Describe.checkReadAccess('Opportunity', setOppFields);
			UTIL_Describe.checkReadAccess('CampaignMember', new Set<String>{
				'ContactId',
				UTIL_Describe.StrTokenNSPrefix('Bid_Number__c'),
				UTIL_Describe.StrTokenNSPrefix('Table_Name_Number__c')
			});
			UTIL_Describe.checkReadAccess('Contact', new Set<String>{
				'Name',
				'MailingAddress'
			});
			enableOpenPDF = true;
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
			enableOpenPDF = false;
		}
	}

	public Boolean enableOpenPDF { get; set; }

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
     
	// public property to get the commandButton URL
	// for the Open button, to open the receipts pdf  
	public String strOpenReceiptURL {
		get {
			String str =  '/apex/GW_Auctions__AuctionReceipts' +
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
			if (fAddressToHousehold == false) {
				str += '&AddressToHousehold=false';
			}
			return str;			
		}
		private set;
	}
	    		
	@TestVisible private Boolean fOpenPDF { get; set; }
	
 	// the currently selected Auction
	public Id auctionId { get; set; }
	
	public Boolean fIncludeTicketPurchases { get; set; }
	
	public Boolean fIncludeAllGuests { get; set; }

	public Boolean fAddressToHousehold { get; set; }

	public Boolean fHasHouseholds {
		get {
			return (AUC_AuctionConstants.strContactHouseholdField != null &&
				AUC_AuctionConstants.strContactHouseholdNameField != null);
		}
	}

	public String strAuctionReceiptsIntro { get {return AUC_AuctionConstants.StrAuctionReceiptsIntro();} }
	
	public String strAuctionReceiptsFooter { get {return AUC_AuctionConstants.StrAuctionReceiptsFooter();} }
	
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions { get; set; }

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
	// has to be a String to allow a null Id ('') to get returned from the page.
	public String contactIdPurchaser { 
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
	public String strNamePurchaser { 
		get {
			if (strNamePurchaser == null && contactIdPurchaser != null) {
				Contact con = [SELECT Name FROM Contact WHERE Id = :contactIdPurchaser];
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

	public PageReference ChangeAddressToHousehold() {
		listReceipts = null;
		listReceipts2 = null;
		listReceipts3 = null;
		listLR = null;
		return null;
	}

	public Boolean HasReceipts {
		get { 
			if (listReceipts == null) return false;
			if (listReceipts.size() == 0) return false;
			return true;
		}
	}

	// the set of Opportunity fields referenced in the field set, and directly in the visualforce page
	private Set<String> setOppFields {
		get {
			if (setOppFields == null) {
				setOppFields = new Set<String>();
				setOppFields.addAll(AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity',
					UTIL_Describe.StrTokenNSPrefix('AuctionReceiptsFS')));
				setOppFields.add('Id');
				setOppFields.add('Name');
				setOppFields.add('StageName');
				setOppFields.add('Amount');
				setOppFields.add('Description');
				setOppFields.add(UTIL_Describe.StrTokenNSPrefix('Auction_Non_Deductible_Amount__c'));
				setOppFields.add(UTIL_Describe.StrTokenNSPrefix('Auction_Deductible_Amount__c'));
				setOppFields.add(UTIL_Describe.StrTokenNSPrefix('Auction_Item_Name__c'));
			}
			return setOppFields;
		}
		set;
	}
	
	// helper routine to return all Opportunity field names from the Field Set and page for the soql
	private String strOppFields {
		get {
			if (strOppFields == null) {
				List<String> listStrFields = new List<String>(setOppFields);
				strOppFields = '';
				for (String str : listStrFields) {
					strOppFields += 'opportunity.' + str + ',';
				}  		
				strOppFields = strOppFields.substring(0, strOppFields.length()-1);
			}
			return strOppFields;
		}
		set;
	}

	public String strErrorMessage { get; set; }
	
	// list of Receipt objects to display
	@TestVisible private List<Receipt> listReceipts {
		get { 
			if (listReceipts != null) return listReceipts;
			
			// if we aren't opening the pdf, then bail out!
			if (!fOpenPDF) return null;
			
			// create the lists of which contacts to include
			List<Id> listContactId = new List<Id>();
			List<Id> listContactId2 = new List<Id>();
			List<Id> listContactId3 = new List<Id>();
			Integer cOverLimit = 0;
			strErrorMessage = null;
			
			if (contactIdPurchaser != null) {
				listContactId.add(contactIdPurchaser);
			} else if (fIncludeAllGuests) {			
				List<AUC_CTRL_AuctionCheckOut.Purchaser> listPurchasers = getListPurchasers(auctionId, '');
				Integer cPurchaser = 0;
				for (AUC_CTRL_AuctionCheckOut.Purchaser p : listPurchasers) {
					cPurchaser++;
					if (cPurchaser <= 1000) {
						listContactId.add(p.contactId);
					} else if (cPurchaser <= 2000) {
						listContactId2.add(p.contactId);
					} else if (cPurchaser <= 3000) {
						listContactId3.add(p.contactId);
					} else { // after 3000, we ignore them!
						cOverLimit++;
					}
				}
			}
			
			// call the real worker.
			listReceipts = listReceiptsForlistContactId(listContactId);
			listReceipts2 = listReceiptsForlistContactId(listContactId2);
			listReceipts3 = listReceiptsForlistContactId(listContactId3);
			if (cOverLimit > 0) {
				strErrorMessage = 'Receipts were printed for ' + 
					String.valueOf(listReceipts.size() + listReceipts2.size() + listReceipts3.size()) +
					' guests.  Auction Receipts has hit its limit, and the last potential ' + String.valueOf(cOverLimit) +
					' receipts were not included.';
			}
			
			return listReceipts;
		}	
	
		set;		
	}
			
	// to handle large auctions, the second list of Receipt objects to display
	@TestVisible private List<Receipt> listReceipts2 {
		get {
			// we fill listReceipts2 at the same time we fill listReceipts1.
			return listReceipts2;
		}		
		private set;		
	}
	
	// to handle large auctions, the third list of Receipt objects to display
	@TestVisible private List<Receipt> listReceipts3 {
		get {
			// we fill listReceipts3 at the same time we fill listReceipts1.
			return listReceipts3;
		}		
		private set;		
	}

	public List<List<Receipt>> listLR {
		get {
			if (listLR == null) {
				listLR = new List<List<Receipt>>();
				listLR.add(listReceipts);
				if (listReceipts2 != null && listReceipts2.size() > 0) {
					listLR.add(listReceipts2);
				}
				if (listReceipts3 != null && listReceipts3.size() > 0) {
					listLR.add(listReceipts3);
				}
			}
			return listLR;
		}
		private set;
	}
			
	// this is the core of the work.  Getting a list of Receipts for contacts who made purchases.
	// each receipt contains a list of the opportunities for the contact.
	// this allows us to use two apex:repeat constructs to loop through the contacts, and all of their opps.
	private List<Receipt> listReceiptsForlistContactId(List<Id> listContactId) {
			
			List<Receipt> listReceiptsT = new List<Receipt>();
			Date dtAuction = AUC_AuctionMaintenance.DateOfAuctionId(auctionId);
	       	Map<Id, Receipt> mapContactIdReceipt = new Map<Id, Receipt>();
	       	String rtPurchase = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem;
	       	String rtGift = AUC_AuctionMaintenance.recordtypeIdAuctionGift;
	       	String rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
	       	String cmpIdAttendees = auctionMaintenance.campaignIdAuctionAttendees;
	       	String cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;
	       	Map<Id, CampaignMember> mapContactIdToCampaignMember = new Map<Id, CampaignMember>();

	       	// create the maps of bid numbers and table names, so we can include them on the report.
	       	List<CampaignMember> listCM = [SELECT ContactId, Bid_Number__c, Table_Name_Number__c FROM CampaignMember WHERE
	       		Bid_Number__c <> NULL AND CampaignId = :cmpIdAttendees AND ContactId IN :listContactId];
	       	for (CampaignMember cm : listCM) {
				mapContactIdToCampaignMember.put(cm.ContactId, cm);
	       	}

			String strSoql = 'SELECT contactId, contact.Name, contact.Firstname, contact.MailingStreet, contact.MailingCity, contact.MailingState, contact.MailingPostalCode, ' +
				' opportunity.RecordType.Name, '; 
			if (AUC_AuctionConstants.strContactHouseholdField != null) {
				strSoql += ' contact.' + AUC_AuctionConstants.strContactHouseholdField + ', ';
				if (AUC_AuctionConstants.IsNPSPInstalled) {
					strSoql += ' contact.npo02__Formula_HouseholdMailingAddress__c, ';
				}
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
				' FROM OpportunityContactRole ' +
				' WHERE IsPrimary=true AND contactId in :listContactId AND ' +
					' (((opportunity.RecordTypeId = :rtPurchase or opportunity.RecordTypeId = :rtGift) ' + 
						' AND opportunity.campaignId = :cmpIdAttendees) ' +
					' OR ' +
					' (opportunity.RecordTypeId = :rtTicket ' +
						' AND opportunity.campaignId = :cmpIdTickets ' +
						' AND IsPrimary=:fIncludeTicketPurchases)) ' +
					' ORDER BY contact.LastName, contact.FirstName';

			// in one soql call, get all the appropriate opportunities for auction purchases and tickets
			for (List<OpportunityContactRole> listOCR : Database.query(strSoql)) {
	       
				// now go through all the opps, and for each contact create the appropriate Receipt objects and their child opportunities.	       
		        for (OpportunityContactRole ocr : listOCR){
		        	Opportunity opp = ocr.Opportunity;
			        	
		        	// this map keeps track of whether we've already created a receipt for this contact or not.
		        	Receipt r = mapContactIdReceipt.get(ocr.ContactId);
		        	if (r == null) {
		        		r = new Receipt();
		        		r.contactId = ocr.ContactId;
		        		r.auctionId = auctionId;
		        		r.listOppAuctionPurchases = new List<Opportunity>();
		        		r.strContactName = ocr.Contact.Name;
		        		r.strContactFirstName = NullStr(ocr.Contact.FirstName);

		        		// use household fields instead if appropriate
						if (fAddressToHousehold && AUC_AuctionConstants.strContactHouseholdNameField != null) {
							List<String> listStr = AUC_AuctionConstants.strContactHouseholdNameField.split('\\.', 0);
							if (listStr.size() > 1) {
								Contact con = ocr.Contact;
								SObject hh = con.getSObject(listStr[0]);
								String strHousehold;

								// avoid non-household accounts with household account model
								if (listStr[0] == 'Account' && 
									AUC_AuctionConstants.isNPSPHouseholdAccountModel &&
									hh.get('npe01__SYSTEM_AccountType__c') != 'Household Account') {
									hh = null;
								}
								
								if (hh != null) strHousehold = (String)hh.get(listStr[1]);
								if (strHousehold != null) r.strContactName = strHousehold;
							}
						}
						if (fAddressToHousehold && AUC_AuctionConstants.strContactHouseholdGreetingField != null) {
							List<String> listStr = AUC_AuctionConstants.strContactHouseholdGreetingField.split('\\.', 0);
							if (listStr.size() > 1) {
								Contact con = ocr.Contact;
								SObject hh = con.getSObject(listStr[0]);
								String strHousehold;

								// avoid non-household accounts with household account model
								if (listStr[0] == 'Account' && 
									AUC_AuctionConstants.isNPSPHouseholdAccountModel &&
									hh.get('npe01__SYSTEM_AccountType__c') != 'Household Account') {
									hh = null;
								}

								if (hh != null) strHousehold = (String)hh.get(listStr[1]);
								if (strHousehold != null) r.strContactFirstName = strHousehold;
							}
						}

						if (fAddressToHousehold && AUC_AuctionConstants.IsNPSPInstalled) {
							r.strContactAddrLine1 = String.valueOf(ocr.Contact.get('npo02__Formula_HouseholdMailingAddress__c'));
							r.strContactAddrLine2 = '';
						}
						if (r.strContactAddrLine1 == null || r.strContactAddrLine1 == '') {
							r.strContactAddrLine1 = NullStr(ocr.Contact.MailingStreet);
							r.strContactAddrLine2 = NullStr(ocr.Contact.MailingCity) + (ocr.Contact.MailingCity <> null ? ', ' : '') +
								NullStr(ocr.Contact.MailingState) + '  ' + NullStr(ocr.Contact.MailingPostalCode);
						}
		        		r.dtAuction = dtAuction;
						CampaignMember cm = mapContactIdToCampaignMember.get(ocr.ContactId);
						if (cm != null) {
							r.strBidNumber = String.valueOf(cm.Bid_Number__c);
							r.strTableNameNumber = cm.Table_Name_Number__c;
						}
		        		mapContactIdReceipt.put(r.contactId, r);
		        		listReceiptsT.add(r);
		        	}
		        	if (opp.Amount == null) opp.Amount = 0;
		        	if (opp.Auction_Non_Deductible_Amount__c == null) opp.Auction_Non_Deductible_Amount__c = 0;
	        		r.listOppAuctionPurchases.add(ocr.Opportunity);
	        		r.decTotalAmountPaid += opp.Amount;
					r.decTotalAmountDeductible += opp.Auction_Deductible_Amount__c;
					r.decTotalFMV += opp.Auction_Non_Deductible_Amount__c;
		        }
	        }
	        
	        //System.debug('**** Leaving listReceipts');
	        return listReceiptsT;
	}

	// helper routine to handle null Strings.
	private String NullStr(String str) {
		if (str == null) return '';
		return str;
	}
	
	//==================== Receipt Class ======================================
	// helper class that holds a contact, and their opportunities
	// the VF Page will iterate through a list of these that the controller provides.
	public class Receipt {
		
		// constructor
		public Receipt() {
			//System.debug('**** Creating Receipt');
			decTotalAmountPaid = 0;
			decTotalAmountDeductible = 0;	
			decTotalFMV = 0;
		}
		
		public Id contactId { get; set; }
		public String strContactName { get; set; }
		public String strContactFirstName { get; set; }		
		public String strContactAddrLine1 { get; set; }		
		public String strContactAddrLine2 { get; set; }		
		public Id auctionId { get; set; }
		public Date dtAuction { get; set; }
		public Decimal decTotalAmountPaid { get; set; }
		public Decimal decTotalAmountDeductible { get; set; }
		public Decimal decTotalFMV { get; set; }
		public List<Opportunity> listOppAuctionPurchases { get; set; }
		public String strBidNumber { get; set; }
		public String strTableNameNumber { get; set; }
		
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
	* @param strFilter the subString to filter by 
	* @return List<Purchaser>, which will be turned into a Javascript collection.
	********************************************************************************************************/
   @RemoteAction global static List<AUC_CTRL_AuctionCheckOut.Purchaser> getListPurchasers(String auctionId, String strFilter) {
   		return AUC_CTRL_AuctionCheckOut.getListPurchasers(auctionId, strFilter);
   }
}