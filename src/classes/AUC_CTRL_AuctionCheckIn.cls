// Written by David Habib, copyright (c) 2012 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckIn { 

	// constructor for the class 
	public AUC_CTRL_AuctionCheckIn() {
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');
		
		// do any initialization which is not dependent on having an auctionId
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;	
						
		// use auctionId passed in if there, else use latest auction.
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

	// private status string for reporting the results of saving.
    private String strSaveResults { get; set; } 

	// status string for reporting helpful instructions and the results of saving.
	public string strStatus {
		
		get {
			boolean fAttendee = contactIdAttendee != null && contactIdAttendee != '';
			boolean fCaptain = idCaptain != null && idCaptain != '';
			boolean fSearchAttendee = searchAttendee != null && searchAttendee != '';
			
			if (strSaveResults != null) {
				strStatus = strSaveResults;
			} else if (!fAttendee && !fCaptain && !fSearchAttendee) {
				strStatus = 'Enter the name of a guest, to search for their ticket and table assignment, and display their information.'; 
			} else if (!fAttendee && fSearchAttendee) {
				strStatus = 'There is no contact in the database with that name.  You can enter a new contact in the New Contact section.';
			} else if (fAttendee && !fCaptain) {
				strStatus = 'Please enter a table captain.';
			} else if (!fAttendee && fCaptain) {
				strStatus = 'You can select one of the guests from the Guest List, search for a new guest, or enter a new guest.';
			} else if (fAttendee && fCaptain) {
				strStatus = 'You can update the guest\'s information and click <b>Save Contact</b>.  You can also save their credit card by clicking <b>Authorize Credit Card</b>.' + 
					'  If the guest needs to buy tickets, click on the <b>Add Ticket Purchase</b> checkbox.';
			}
			return strStatus;
		}
		private set;
	}
	
	private AUC_AuctionMaintenance auctionMaintenance;
		
	// the currently selected Auction
	public Id auctionId { get; set; }
		
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }

	// callback when the user changes the current auction in the dropdown.
	public PageReference ChangeAuction() {
		// clear any previous save message
		strSaveResults = null;
		
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;

		// setting contactId's to null will null out their dependencies.
		contactIdAttendee = null;
		idCaptain = null;
		return null;
	}  

	// holds the currently selected Attendee contact
	// has to be a string to allow a null Id ('') to get returned from the page.
	public string contactIdAttendee { 
		get; 
		set {
			// first invalidate anything dependent on a change
			if (contactIdAttendee != value) {
				strNameAttendee = null;
				attendeeEdit = null;
				oppTicketAttendee = null;
				strCreditCardValidateURL = null;
			}
			contactIdAttendee = value;
			if (contactIdAttendee == '') contactIdAttendee = null; 
		}		
	}
	
	// holds the currently selected Attendee's name	
	public string strNameAttendee { 
		get {
			if (strNameAttendee == null && contactIdAttendee != null) {
				Contact con = [select Name from Contact where Id = :contactIdAttendee];
				strNameAttendee = con.Name;
			}
			return strNameAttendee;
		}
		private set;
	}
			
	// callback when the user changes the Attendee contact lookup.
	public PageReference ChangeAttendeeLookup() {
		// clear any previous save message
		strSaveResults = null;
		
		// the setter for contactIdAttendee will 
		// automatically invalidate any dependencies!

		// see if they already have a captain, and only update the current
		// captain if we've found a new one.
		ID id = idCaptainForcontactIdAttendee(contactIdAttendee);
		if (id != null) idCaptain = id;
		return null;
	}  
	
	// this parameter is used in scenarios where the page
	// needs us to search for an attendee before it could wait
	// for the return from its javascript remoting call to get data
	public string searchAttendee { get; set; }
	
	// callback when the user changes the Attendee contact lookup and submits too quick.
	public PageReference SearchAttendeeLookup() {
		if (searchAttendee != null && searchAttendee != '') {
			list<Contact> listCon = [select Id from Contact where Name = :searchAttendee];
			if (listCon.size() > 0) {
				contactIdAttendee = listCon[0].Id;
			} else {
				contactIdAttendee = null;
				strSaveResults = null;
				strNameAttendee = searchAttendee; // to keep displaying the text.
				return null;
			}
		} else {
			contactIdAttendee = null;	
			strNameAttendee = null;		
		}
		return ChangeAttendeeLookup();
	}

	// utility to find the Captain for an Attendee
	private ID idCaptainForcontactIdAttendee(ID idAttendee) {		

		// get the CampaignMember for the attendee
		list<CampaignMember> listCM = [select contactId, Auction_Ticket_OppId__c, Table_Captain__c from CampaignMember 
			where contactId = :idAttendee and campaignId = :auctionMaintenance.campaignIdAuctionAttendees ];
		if (listCM.size() > 0) {
			if (listCM[0].Table_Captain__c != null) {
				// if they have a table captain, use it
				return listCM[0].Table_Captain__c;
			} else {
				// otherwise return the ticket purchaser
				list<OpportunityContactRole> listOCR = [select contactId from OpportunityContactRole 
						where IsPrimary=true and opportunityId = :listCM[0].Auction_Ticket_OppId__c];
				if (listOCR.size() > 0) {
					return listOCR[0].contactId;
				} else {
					// if we didn't find a OCR, it might be just an ticket bought by an Account.
					list<Opportunity> listOpp = [select accountId from Opportunity where Id = :listCM[0].Auction_Ticket_OppId__c];
					if (listOpp.size() > 0) {
						return listOpp[0].accountId;
					}
				}
			}
		}
		return null;
	}
	
	// holds the currently selected Captain.  
	// Note that this can be either a Contact ID or an Account ID
	// has to be a string to allow a null Id ('') to get returned from the page.
	public string idCaptain { 
		get; 
		set {
			// invalidate anything dependent on a change
			if (idCaptain != value) {
				strNameCaptain = null;
				attendeeEdit = null;
				listAttendees = null;
				oppCaptain = null;
			}
			idCaptain = value;			
			if (idCaptain == '') idCaptain = null; 
		}
	}
	
	// differentiates whether our table captain is a Contact or an Account
	public boolean IsCaptainContact {
		get {
			if (idCaptain == null || 
				AUC_AuctionConstants.getObjectTypeFromId(idCaptain) == Contact.sObjectType) {
				return true;
			} else
				return false;
		}
	}
	
	// holds the currently selected Captain's name	
	public string strNameCaptain { 
		get {
			if (strNameCaptain == null && idCaptain != null) {
				if (IsCaptainContact) {				
					Contact con = [select Name from Contact where Id = :idCaptain];
					strNameCaptain = con.Name;
				} else {
					Account acc = [select Name from Account where Id = :idCaptain];
					strNameCaptain = acc.Name;	
				}
			}
			return strNameCaptain;
		}
		private set;
	}

	// callback when the user changes the Table Captain contact lookup.
	public PageReference ChangeCaptainLookup() {
		// clear any previous save message
		strSaveResults = null;
		// the setter for idCaptain will
		// invalidate anything dependent.
		return null;
	}  
	
	// the ticket opportunity for the currently selected Captain
	private Opportunity oppCaptain { 
		get {
			if (oppCaptain == null) {	
				// if we have a table captain, look for their ticket first.
				if (idCaptain != null) {
					list<Opportunity> listOpp;
					if (IsCaptainContact) {
					 	listOpp = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount 
							from Opportunity 
							where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
								and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
								and Id in (select OpportunityId from OpportunityContactRole where contactId = :idCaptain)];
					} else {
						listOpp = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount
							from Opportunity
							where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
								and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
								and AccountId  = :idCaptain];
					}
					if (listOpp.size() > 0) {
						oppCaptain = listOpp[0];
						return oppCaptain;
					}					
				}
				// if there is no ticket holder, create a new ticket opp.
				oppCaptain = new Opportunity(
					RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
					CampaignId = auctionMaintenance.campaignIdAuctionTickets
				);
			} 
			return oppCaptain;
		}
		private set; 
	}  
	
	// flag to track whether to add a ticket purchase for the Attendee
	public boolean fAddTicketPurchase { get; set; }
	
	// the optional ticket opportunity for the current Attendee
	public Opportunity oppTicketAttendee {
		get {
			if (oppTicketAttendee == null) {
				oppTicketAttendee = new Opportunity(
					RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
					CampaignId = auctionMaintenance.campaignIdAuctionTickets,
					CloseDate = system.Today()
				);
			}
			return oppTicketAttendee;
		}
		private set;
	}
		
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public list<Attendee> listAttendees {
    	get {
    		if (listAttendees == null) {
    			listAttendees = new list<Attendee>(); 			
    			
    			// find any existing attendees on this ticket
    			if (oppCaptain.Id != null) {
    				
	    			// load up their CM info.
	    			string strSoql = 'select ' + strCMFields +
    					' from CampaignMember' + 
    					' where campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' and ' +
    						' (GW_Auctions__Auction_Ticket_OppId__c = \'' + oppCaptain.Id + '\'';
    				if (IsCaptainContact) {
    					strSoql += 'or GW_Auctions__Table_Captain__c = \'' + idCaptain+ '\'';
    				}
    				strSoql += ')';
    				
    				list<CampaignMember> listCM = Database.query(strSoql);
    					
    				// create a map so we can match CM's with Contacts
    				map<ID, CampaignMember> mapContactIdCM = new map<ID, CampaignMember>();
    				for (CampaignMember cm : listCM) {
    					mapContactIdCM.put(cm.contactId, cm);
    				}    			

	    			// load up their contact info.
	    			set<ID> setKeys = mapContactIdCM.keySet();
	    			list<Contact> listCon = Database.query('select ' + strContactFields + 
	    				' from Contact where Id in :setKeys' + 
	    				' order by Name');    			
    			
	    			for (Contact con : listCon) {
	    				listAttendees.add(new Attendee(mapContactIdCM.get(con.Id), con));
	    			}
	    			    					
					// create new CampaignMembers for any additional attendees on this ticket    					
		    		double numTickets = oppCaptain.Number_Of_Tickets__c;
		    		if (numTickets == null || numTickets == 0) numTickets = 1;
		            for (integer i = listCon.size()+1; i <= numTickets; i++) {
		                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);		                
	                	cmpmbr.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
	                	cmpmbr.Status = 'RSVP Yes';
	                	cmpmbr.Paid__c = (oppCaptain.amount != null);
	                	
	                	Contact con = new Contact();
	    				listAttendees.add(new Attendee(cmpmbr, con));
		            }
		        }
    		}
	        return listAttendees;
    	}

    	private set;    	
    } 	

	// helper routine to return all Contact field names from the Field Set
	// (which of course we currently can't get in Apex, so get them all!!)
	private string strContactFields {
		get {
			if (strContactFields == null) {
				
				// initialize the list of all fields on Contact.
				// ideally, we'd only include the fields in the Field Set,
				// but Apex currently has no way to see what those are.
				// so for now, we just include all fields on Contact.
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Contact.fields.getMap();
				list<string> listStrFields = new list<string>();
				listStrFields.addAll(mapS.keySet());  
				strContactFields = '';
				for (string str : listStrFields) {
					strContactFields += str + ',';
				}  		
				strContactFields = strContactFields.substring(0, strContactFields.length()-1);
			}
			return strContactFields;
		}
		set;
	}
	
	// helper routine to return all CampaignMember field names from the Field Set
	// (which of course we currently can't get in Apex, so get them all!!)
	private string strCMFields {
		get {
			if (strCMFields == null) {
				
				// initialize the list of all fields on Contact.
				// ideally, we'd only include the fields in the Field Set,
				// but Apex currently has no way to see what those are.
				// so for now, we just include all fields on Contact.
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.CampaignMember.fields.getMap();
				list<string> listStrFields = new list<string>();
				listStrFields.addAll(mapS.keySet());  
				strCMFields = '';
				for (string str : listStrFields) {
					strCMFields += str + ',';
				}  		
				strCMFields = strCMFields.substring(0, strCMFields.length()-1);
			}
			return strCMFields;
		}
		set;
	}

	// an Attendee object to hold Contact and CampaignMember fields to support the editing pane
	public Attendee attendeeEdit { 
		get {
			if (attendeeEdit == null) {
				// see if we already have their info loaded
				attendeeEdit = attendeeFromId(contactIdAttendee);				
				// if not loaded (not a current Attendee), then look it up
				if (attendeeEdit == null) {	
					Contact con = new Contact();				
	                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                	cmpmbr.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
                	cmpmbr.contactId = contactIdAttendee;
                	cmpmbr.Status = 'RSVP Yes';

					if (contactIdAttendee != null) {
						con = Database.Query('select ' + strContactFields + ' from Contact where Id = :contactIdAttendee');

		                // we still need to make sure they don't already have a CM.  only happens in a case where the CM
		                // is no longer attached to either a Ticket Opp or a Table Captain.
		    			string strSoql = 'select ' + strCMFields +
	    					' from CampaignMember' + 
	    					' where campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' and ' +
	    						' contactId = :contactIdAttendee';
	    				list<CampaignMember> listCM = Database.query(strSoql);
	    				if (listCM.size() > 0) {
	    					cmpmbr = listCM[0];
	    					if (cmpmbr.Table_Captain__c == null) {
	    						// go ahead and prefill the current table captain.
			                	cmpmbr.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
	    					}
	                	cmpmbr.Status = 'RSVP Yes';
	    				}
					}
                	attendeeEdit = new Attendee(cmpmbr, con);
				}
			}
			return attendeeEdit; 
		}
		private set;
	}

	// find the Attendee for the given contactId.
	private Attendee attendeeFromId(ID cId) {
		if (cId == null) return null;
		for (Attendee att : listAttendees) {
			if (att.con.Id == cId) {
				return att;
			}
		}
		return null;
	}
	
	// list for Stage picklist, filtered correctly for stages for Auction Ticket opps.
	public list<SelectOption> listSOTicketStages {
		get {
			if (listSOTicketStages == null) {
				listSOTicketStages = new list<SelectOption>();
				
				// since we can't seem to get the styling for a required field for Stage,
				// we won't provide a blank option!
				//listSOTicketStages.add(new SelectOption('', ''));
				
				string strStages = AUC_AuctionConstants.StrTicketOpportunityStages();
				
				// if setting returns strings, use them
				if (strStages != null) {
					list<string> listStr = strStages.split(';');
					for (string  str : listStr) {
						listSOTicketStages.add(new SelectOption(str, str));						
					}					
				} else { // otherwise use the current Salesforce Opp Stages			
					for (OpportunityStage stg : [select Id, MasterLabel from OpportunityStage where IsActive=true order by SortOrder]) {
						listSOTicketStages.add(new SelectOption(stg.MasterLabel, stg.MasterLabel));
					}
				}
			}
			return listSOTicketStages;
		}
		private set;
	}
					
	// save all modified data.  a complex process to handle both updates and inserts!
	public PageReference SaveAttendeeInfo() {
		         
        strSaveResults = 'Starting Save...';
        try {
			// bail out if we aren't set up.
			if (attendeeEdit == null || attendeeEdit.con == null) {
				strSaveResults = 'There is no guest selected to save.';
				return null;
			}
							
			// Steps:
			// 	1. create or update Contact
			// 	2. create optional Ticket Opp
			// 	3. create or update CampaignMember
			//	4. cleanup

			// 1. Create or Update the Attendee Contact.
			if (attendeeEdit.con.Id == null) {
				insert attendeeEdit.con;
			} else {
				update attendeeEdit.con;
			}
      	
      		// 2. create optional Ticket
      		if (fAddTicketPurchase) {        	
	        	// create the opp for the ticket purchase        	
				Contact contact = [select Name, AccountId from Contact where Id=:contactIdAttendee];	
				string strAuction = AUC_AuctionMaintenance.NameOfAuctionId(AuctionId);
				// remove trailing word Auction if it's there, so we don't get "auction" auction ticket.
				if (strAuction != null && strAuction.endsWith(' Auction')) {
					strAuction = strAuction.substring(0, strAuction.length() - 8);
				}
				oppTicketAttendee.Name = contact.Name + ' ' + strAuction + ' ' + AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket;   
				oppTicketAttendee.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(AuctionId) * 
					oppTicketAttendee.Number_Of_Tickets__c;      	
	        	
	            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
				// if so, we need to set the Opp's Account to make the rollups work.
				if (AUC_AuctionConstants.isOneToOne()) {
					oppTicketAttendee.AccountId = contact.AccountId;
				}
					        	
	        	if (oppTicketAttendee.Id == null) {
	        		insert oppTicketAttendee;
					
					// only create contact role if client's code didn't do it!
					if (AUC_AuctionConstants.fCreateOppContactRoles(oppTicketAttendee.Id, contactIdAttendee)) {				
		        		OpportunityContactRole ocr = new OpportunityContactRole();
						ocr.OpportunityId = oppTicketAttendee.Id;
						ocr.contactId = contactIdAttendee;
			        	ocr.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
						ocr.IsPrimary = true;
						insert ocr;
					}
	        	}
      		}
      		
			// 3. create or update CampaignMember
			if (attendeeEdit.cm.Id == null) {
				attendeeEdit.cm.campaignId = auctionMaintenance.campaignIdAuctionAttendees;
				attendeeEdit.cm.contactId = attendeeEdit.con.Id;
			}
			attendeeEdit.cm.Auction_Ticket_OppId__c = (fAddTicketPurchase ? oppTicketAttendee.Id : oppCaptain.Id);
			if (fAddTicketPurchase) {
				attendeeEdit.cm.Paid__c = true;
			}
			if (attendeeEdit.cm.id == null) {
				insert attendeeEdit.cm;				
			} else {
				update attendeeEdit.cm;
			}      					
			       	
        	strSaveResults = 'The Guest information has been saved.';
        	
			// 4. save done, so clear our complete state
			listAttendees = null;	
			oppTicketAttendee = null;
			oppCaptain = null;	
			fAddTicketPurchase = false;
			strNameAttendee = null;
			strNameCaptain = null;
			
			// when the page reloads, let's make sure we show the current attendee and (possibly new) captain.
			contactIdAttendee = attendeeEdit.con.Id;
			if (attendeeEdit.cm.Table_Captain__c != null) {
				idCaptain = attendeeEdit.cm.Table_Captain__c;
			}
			return null;	
			        
        } catch (Exception e) {
           	strSaveResults = 'Error encountered while trying to save.  ';
            ApexPages.addMessages(e);            
            return null;
        }               
	}

	// public method for the Close button.  
	// use retURL if we have it, otherwise go to tickets tab.
	public PageReference Close() {
		string retURL = ApexPages.currentPage().getParameters().get('retURL');
		if (retURL == null || retURL == '') {
			retURL = '/apex/GW_Auctions__AuctionTickets';
		}
		PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
	}

	// public property to get the commandButton URL
	// for the Authorize Credit Card button.	
	public string strCreditCardValidateURL {
		get {
			if (strCreditCardValidateURL == null) {
				string str = AUC_AuctionConstants.StrCreditCardValidateURLFormula();
				if (str != null) {
					str = string.format(str, new list<string> { contactIdAttendee });
				}
				strCreditCardValidateURL = str;
			}
			return strCreditCardValidateURL;
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

	/*******************************************************************************************************
	* @description Attendee Class is a helper class that holds a contact and their campaign member.
	********************************************************************************************************/
	public class Attendee {
		
		// constructor
		public Attendee(CampaignMember cmT, Contact conT) {
			cm = cmT;
			con = conT;
		}
		
		public CampaignMember cm { get; set; }
		public Contact con { get; set; }		
	}
	

	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts, optionally filtered by strFilter.
	* @param strFilter the substring to filter by 
	* @return list<Contact>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static list<Contact> getListContacts(string strFilter) {
    	strFilter = '%' + strFilter + '%';   	
        list<Contact> listContacts = [select Id, Name, MailingStreet, MailingCity 
        		from Contact where 
				Name like :strFilter 
				order by Name asc];
			
		return listContacts;
    } 		
	
	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts and Accounts, who are ticket 
	* holders or table captains on the specified auction, optionally filtered by strFilter.
	* @param auctionId the Auction to filter by 
	* @param strFilter the substring to filter by 
	* @return list<SObject>, (Contacts and Accounts) which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static list<SObject> getListCaptains(string auctionId, string strFilter) {
    	strFilter = '%' + strFilter + '%';   	

		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;
		
		set<ID> setContactId = new set<ID>();
		set<ID> setOppId = new set<ID>();
		
		// get all the primary contacts for auction tickets
		for (list<OpportunityContactRole> listOCR : [select contactId, opportunityId from OpportunityContactRole 
			where IsPrimary=true and 
			(opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets) and
			contact.Name like :strFilter]) {
			
			// use set to avoid dups
			for (OpportunityContactRole ocr : listOCR) {
				setContactId.add(ocr.contactId);
				setOppId.add(ocr.opportunityId);
			}
		}
		
		// get all the table captains
		for (list<CampaignMember> listCM : [select contactId, Table_Captain__c from CampaignMember 
			where campaignId = :auctionMaintenance.campaignIdAuctionAttendees and
			Table_Captain__r.Name like :strFilter]) {
			
			// use set to avoid dups
			for (CampaignMember cm : listCM) {
				setContactId.add(cm.Table_Captain__c);
			}
		}
		list<SObject> listContactCaptains = [select Id, Name from Contact where Id in :setContactId order by Name];	
		
		// now add any Accounts that own tickets.
		// since we don't really want to include 1:1 accounts when dealing with NPSP,
		// nor do we want accounts that were listed on the opp if there still was an individual ticket purchaser,
		// we filter out opps that have primary contacts.
		set<ID> setAccId = new set<ID>();
		for (list<Opportunity> listOpp : [select accountId from Opportunity
			where campaignId=:auctionMaintenance.campaignIdAuctionTickets and
			account.Name like :strFilter and
			Id not in :setOppId]) {
			
			// use set to avoid dups
			for (Opportunity opp : listOpp) {
				setAccId.add(opp.accountId);
			}
		}
		list<SObject> listAccountCaptains = [select Id, Name from Account where Id in :setAccId order by Name];

		// add our list of contacts and accounts together
		list<SObject> listSobj = new list<SObject>();
		listSobj.addAll(listContactCaptains);
		listSobj.addAll(listAccountCaptains);	
		return listSobj; 
    } 	
    	
	//==================== TEST METHOD(s) ======================================
	public static testmethod void CodeCoverageTests() {
    	
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction; 
		System.Assert(auction.id != null); 	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign 
    		where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	
    	Account acc = new Account(Name='My Test Account');
    	insert acc;
    	
    	Contact contact = new Contact(
    		Firstname = 'Johnny',
    		Lastname = 'Test',
    		AccountId = acc.Id
    	);
    	insert contact;    	

		//instantiate the controller with no page parameters.
		AUC_CTRL_AuctionCheckIn ctrl = new AUC_CTRL_AuctionCheckIn();
		system.assert(ctrl != null);
		ctrl.SaveAttendeeInfo();
		system.assert(ctrl.strSaveResults != null);

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionCheckIn');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		ctrl = new AUC_CTRL_AuctionCheckIn();
		system.assertEquals(auction.Id, ctrl.auctionId);
		ctrl.ChangeAuction();
		system.assertEquals(auction.Id, ctrl.auctionId);
		system.assertEquals(auction.Id, ctrl.auctionMaintenance.auctionId);
		
		// test the initial state
		system.assertEquals(null, ctrl.contactIdAttendee);
		system.assertEquals(null, ctrl.idCaptain);
		system.assertEquals(null, ctrl.strNameAttendee);
		system.assertEquals(null, ctrl.strNameCaptain);
		system.assertEquals(null, ctrl.searchAttendee);
		system.assertEquals(null, ctrl.strSaveResults);
		system.assert(ctrl.attendeeEdit != null);
		system.assert(ctrl.attendeeEdit.con != null);
		system.assert(ctrl.attendeeEdit.cm != null);
		system.assert(ctrl.oppTicketAttendee != null);
		system.assert(ctrl.listSOAuctions.size() > 0);
		system.assert(ctrl.listSOTicketStages.size() > 0);
		system.assert(ctrl.listSOAuctions.size() > 0);
		system.assert(ctrl.listAttendees.size() == 0);
		system.assertEquals(null, ctrl.attendeeFromId(null));
		system.assertEquals(null, ctrl.idCaptainForcontactIdAttendee(null));
		system.assertEquals(null, ctrl.fAddTicketPurchase);
		system.assertEquals(true, ctrl.IsCaptainContact);
		ctrl.ChangeAttendeeLookup(); 
		ctrl.ChangeCaptainLookup();
		ctrl.Close();
		ctrl.SaveAttendeeInfo();
		ctrl.SearchAttendeeLookup();
		
		// set a contact
		ctrl.contactIdAttendee = contact.Id;
		ctrl.ChangeAttendeeLookup();
		system.assertEquals('Johnny Test', ctrl.strNameAttendee);
		system.assert(ctrl.attendeeEdit != null);
		system.assert(ctrl.attendeeEdit.con.Id == contact.Id);
		system.assert(ctrl.attendeeEdit.cm != null);
		
		// save a Contact's ticket purchase
		ctrl.fAddTicketPurchase = true;
		ctrl.oppTicketAttendee.amount = 100;
		ctrl.oppTicketAttendee.number_of_Tickets__c = 4;
		ctrl.oppTicketAttendee.StageName = 'Won Closed';
		ctrl.SaveAttendeeInfo();
		system.assert(ctrl.strSaveResults != null);
		list<CampaignMember> listCM = [select contactId, campaignId, Auction_Ticket_OppId__c, Table_Captain__c from CampaignMember 
			where contactId = :contact.Id and campaignId = :ctrl.auctionMaintenance.campaignIdAuctionAttendees];
		system.assertEquals(1, listCM.size());	
		system.assertEquals(null, ctrl.idCaptain);
		ctrl.contactIdAttendee = contact.Id;
		ctrl.ChangeAttendeeLookup();
		system.assertEquals(contact.Id, ctrl.idCaptainForcontactIdAttendee(contact.Id));
		system.assertEquals(contact.Id, ctrl.idCaptain);
		system.assertEquals('Johnny Test', ctrl.strNameCaptain);
		system.assertEquals(4, ctrl.listAttendees.size());
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.idCaptain = null;
		ctrl.ChangeCaptainLookup();
		system.assertEquals(0, ctrl.listAttendees.size());
		
		// test search functionality
		ctrl.searchAttendee = 'A bogus name you will not find!';
		ctrl.SearchAttendeeLookup();
		system.assertEquals(null, ctrl.contactIdAttendee);
		ctrl.searchAttendee = 'Johnny Test';
		ctrl.SearchAttendeeLookup();
		system.assertEquals(contact.Id, ctrl.contactIdAttendee);
		system.assertEquals(contact.Id, ctrl.idCaptain);
		system.assertEquals(4, ctrl.listAttendees.size());
		
		// save a new contact as an attendee
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.attendeeEdit.con.FirstName = 'Janey';
		ctrl.attendeeEdit.con.LastName = 'Test';
		system.assertEquals(contact.Id, ctrl.attendeeEdit.cm.Table_Captain__c);
		system.assertEquals(null, ctrl.strSaveResults);
		ctrl.SaveAttendeeInfo();
		system.assert(ctrl.strSaveResults != null);
		system.assert(ctrl.contactIdAttendee != null);
		system.assert(ctrl.contactIdAttendee != contact.Id);
		system.assertEquals(true, ctrl.IsCaptainContact);
		system.assertEquals(contact.Id, ctrl.idCaptainForcontactIdAttendee(ctrl.contactIdAttendee));
				
		// test out an account table captain
		Opportunity opp = new Opportunity(				
			RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
			CampaignId = ctrl.auctionMaintenance.campaignIdAuctionTickets
		);				
		opp.AccountId = acc.Id;
		opp.Amount = 1000;
		opp.StageName = 'Won Closed';
		opp.Number_Of_Tickets__c = 10;
		opp.Name = 'my test account ticket purchase';
		opp.CloseDate = system.today();
		insert opp;
		ctrl.idCaptain = acc.Id;
		ctrl.ChangeCaptainLookup();
		system.assertEquals('My Test Account', ctrl.strNameCaptain);
		system.assertEquals(false, ctrl.IsCaptainContact);
		system.assertEquals(acc.Id, ctrl.idCaptain);
		system.assert(ctrl.oppCaptain != null);
		system.debug(ctrl.listAttendees);
		system.assertEquals(10, ctrl.listAttendees.size());
		
		// save another contact to the account table
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.idCaptain = acc.Id;
		ctrl.ChangeCaptainLookup();
		ctrl.attendeeEdit.con.FirstName = 'Joey';
		ctrl.attendeeEdit.con.LastName = 'Test';
		system.assertEquals(null, ctrl.strSaveResults);
		ctrl.SaveAttendeeInfo();
		system.assert(ctrl.strSaveResults != null);
		system.assertEquals(opp.Id, ctrl.attendeeEdit.cm.Auction_Ticket_OppId__c);
		system.assert(ctrl.contactIdAttendee != null);	
		system.assertEquals(acc.Id, ctrl.idCaptainForcontactIdAttendee(ctrl.contactIdAttendee));

		// test remoting functions
		system.assert(AUC_CTRL_AuctionCheckIn.getListContacts('Test').size() >= 3);		
		system.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Johnny Test').size() >= 1);
		system.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'My Test Account').size() >= 1);
					
				
	}		

}