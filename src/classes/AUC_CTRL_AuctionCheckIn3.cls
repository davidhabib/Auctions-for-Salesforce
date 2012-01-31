// Written by David Habib, copyright (c) 2012 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckIn3 { 

	// constructor for the class 
	public AUC_CTRL_AuctionCheckIn3() {
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
	}

	private AUC_AuctionMaintenance auctionMaintenance;
		
	// the currently selected Auction
	public Id auctionId { get; set; }
		
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }

	// callback when the user changes the current auction in the dropdown.
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		strSaveResults = null;

		// setting contactId's to null will null out their dependencies.
		contactIdAttendee = null;
		contactIdCaptain = null;
		return null;
	}  

	// holds the currently selected Attendee contact
	// has to be a string to allow a null Id to get returned from the page.
	public string contactIdAttendee { 
		get; 
		set {
			// first invalidate anything dependent on a change
			if (contactIdAttendee != value) {
				strNameAttendee = null;
				attendeeEdit = null;
				oppTicketAttendee = null;
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
		// the setter for contactIdAttendee will 
		// automatically invalidate any dependencies!

		// if there is no table captain currently selected, see if they have one.
		if (contactIdCaptain == null) {
			contactIdCaptain = contactIdCaptainForcontactIdAttendee(contactIdAttendee);
		}
		return null;
	}  
	
	// utility to find the Captain for a Attendee
	private ID contactIdCaptainForcontactIdAttendee(ID idAttendee) {		

		// first look for the table captain.
		list<CampaignMember> listCM = [select contactId, Auction_Ticket_OppId__c, Table_Captain__c from CampaignMember 
			where contactId = :idAttendee and campaignId = :auctionMaintenance.campaignIdAuctionAttendees ];
		if (listCM.size() > 0) {
			if (listCM[0].Table_Captain__c != null) {
				return listCM[0].Table_Captain__c;
			} else {
				list<OpportunityContactRole> listOCR = 
					[select contactId from OpportunityContactRole 
						where IsPrimary=true and opportunityId = :listCM[0].Auction_Ticket_OppId__c];
				if (listOCR.size() > 0) {
					return listOCR[0].contactId;
				}
			}
		}
		return null;
	}
	
	// holds the currently selected Captain (Table Captain)
	public ID contactIdCaptain { 
		get; 
		set {
			// invalidate anything dependent on a change
			if (contactIdCaptain != value) {
				strNameCaptain = null;
				attendeeEdit = null;
				listAttendees = null;
				oppCaptain = null;
			}
			contactIdCaptain = value;			
		}
	}
	
	// holds the currently selected Captain's name	
	public string strNameCaptain { 
		get {
			if (strNameCaptain == null && contactIdCaptain != null) {
				Contact con = [select Name from Contact where Id = :contactIdCaptain];
				strNameCaptain = con.Name;
			}
			return strNameCaptain;
		}
		private set;
	}

	// callback when the user changes the Table Captain contact lookup.
	public PageReference ChangeCaptainLookup() {
		// the setter for contactIdCaptain will
		// invalidate anything dependent.
		return null;
	}  
	
	// the ticket opportunity for the currently selected Ticket Holder
	private Opportunity oppCaptain { 
		get {
			if (oppCaptain == null) {	
				// if we have a table captain, look for their ticket first.
				if (contactIdCaptain != null) {
					list<Opportunity> listOpp = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount 
						from Opportunity 
						where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
							and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
							and Id in (select OpportunityId from OpportunityContactRole where contactId = :contactIdCaptain)];
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
    				 list<CampaignMember> listCM = [select contactId, Id, campaignId, Status, Is_Table_Captain__c, Auction_Ticket_OppId__c,
    					Bid_Number__c, Meal_Preference__c, Paid__c, Table_Captain__c, Table_Name_Number__c
    					from CampaignMember 
    					where campaignId = :auctionMaintenance.campaignIdAuctionAttendees and
    						(Auction_Ticket_OppId__c = :oppCaptain.Id or Table_Captain__c = :contactIdCaptain)];
    			
    				// create a map so we can match CM's with Contacts
    				map<ID, CampaignMember> mapContactIdCM = new map<ID, CampaignMember>();
    				for (CampaignMember cm : listCM) {
    					mapContactIdCM.put(cm.contactId, cm);
    				}    			

	    			// load up their contact info.
	    			list<Contact> listCon = [select Id, FirstName, LastName, Name, MailingStreet, MailingCity,
	    				MailingState, MailingPostalCode, Email, Phone from Contact where Id in :mapContactIdCM.keySet()
	    				order by Name ];    			
    			
	    			for (Contact con : listCon) {
	    				listAttendees.add(new Attendee(mapContactIdCM.get(con.Id), con));
	    			}
	    			    					
					// create new CampaignMembers for any additional attendees on this ticket    					
		    		double numTickets = oppCaptain.Number_Of_Tickets__c;
		    		if (numTickets == null || numTickets == 0) numTickets = 1;
		            for (integer i = listCon.size()+1; i <= numTickets; i++) {
		                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
	                	cmpmbr.Table_Captain__c = contactIdCaptain;
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
	
	// an Attendee object to hold Contact and CampaignMember fields to support the editing pane
	public Attendee attendeeEdit { 
		get {
			if (attendeeEdit == null) {
				// see if we already have their info loaded
				attendeeEdit = attendeeFromId(contactIdAttendee);				
				// if not loaded (not a current Attendee), then look it up
				if (attendeeEdit == null) {					
					if (contactIdAttendee != null) {
						Contact con = Database.Query('select ' + strContactFields + ' from Contact where Id = :contactIdAttendee');
		                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
	                	cmpmbr.Table_Captain__c = contactIdCaptain;
	                	cmpmbr.contactId = contactIdAttendee;
	                	cmpmbr.Status = 'RSVP Yes';
	                	attendeeEdit = new Attendee(cmpmbr, con);
					} else {
						attendeeedit = new Attendee();
					}	                
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
			
	// status string for reporting the results of saving.
    public String strSaveResults { get; set; }    
	
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
				oppTicketAttendee.Name = contact.Name + ' ' + string.valueof(oppTicketAttendee.CloseDate.year()) + 
					AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket;   
				oppTicketAttendee.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(AuctionId) * 
					oppTicketAttendee.Number_Of_Tickets__c;      	
	        	if (oppTicketAttendee.amount != null) {
	        		oppTicketAttendee.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
	        	} else {
	        		oppTicketAttendee.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;       		
	        	}
	        	
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
			attendeeEdit = null;
			oppTicketAttendee = null;
			oppCaptain = null;	
			fAddTicketPurchase = false;
			strNameAttendee = null;
			strNameCaptain = null;
			
			// when the page reloads, let's make sure we show the current attendee and (possibly new) captain.
			contactIdAttendee = attendeeEdit.con.Id;
			contactIdCaptain = attendeeEdit.cm.Table_Captain__c;
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
	
	/*******************************************************************************************************
	* @description Attendee Class is a helper class that holds a contact and their campaign member.
	********************************************************************************************************/
	public class Attendee {
		
		// constructor
		public Attendee() {
			cm = new CampaignMember();
			con = new Contact();
		}

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
        list<Contact> listContacts = [select Id, Name, Email, MailingStreet, MailingCity 
        		from Contact where 
				Name like :strFilter 
				order by Name asc];
			
		return listContacts;
    } 		
	
	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts, who are ticket holders on
	* the specified auction, optionally filtered by strFilter.
	* @param auctionId the Auction to filter by 
	* @param strFilter the substring to filter by 
	* @return list<Contact>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static list<Contact> getListCaptains(string auctionId, string strFilter) {
    	strFilter = '%' + strFilter + '%';   	

		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;
		
		set<ID> setContactId = new set<ID>();
		list<Contact> listCaptains = new list<Contact>();

		// in one soql call, get all the appropriate opportunities for auction tickets
		for (list<OpportunityContactRole> listOCR : [select contactId, contact.Name from OpportunityContactRole 
			where IsPrimary=true and 
			(opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets) and
			contact.Name like :strFilter
			order by contact.Name]) {
			
			// use set to avoid dups
			for (OpportunityContactRole ocr : listOCR) {
				setContactId.add(ocr.contactId);
			}
		}
		
		listCaptains = [select Id, Name from Contact where Id in :setContactId	order by Name];		
		return listCaptains; 
    } 		

}