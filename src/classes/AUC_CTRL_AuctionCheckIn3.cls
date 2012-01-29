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
		contactIdTicketHolder = null;
		oppTicket = null;
		listAttendees = null;	
		return null;
	}  

	// holds the currently selected Guest contact
	// has to be a string to allow a null Id to get returned from the page.
	public string contactIdGuest { 
		get; 
		set {
			contactIdGuest = value;
			if (contactIdGuest == '') contactIdGuest = null; 
		}		
	}
		
	// callback when the user changes the Guest contact lookup.
	public PageReference ChangeGuestLookup() {
		// clear out all state that is specific to the contact
		attendeeEdit = null;

		ID contactIdTicketHolderCurrent = contactIdTicketHolder;
		contactIdTicketHolder = contactIdTicketForcontactIdGuest(contactIdGuest);
		if (contactIdTicketHolderCurrent != contactIdTicketHolder) {
			oppTicket = null;
			listAttendees = null;
		}
		
		return null;
	}  
	
	// utility to find the TicketHolder for a Guest
	private ID contactIdTicketForcontactIdGuest(ID idGuest) {		
		// look for CM for this guest on the auction's attendee campaign.
		// then see if it has a Auction_Ticket_OppId__c.
		// if it does, then look for a contact role for that opp, which is primary, 
		// to get the ticket holder.		
		list<OpportunityContactRole> listOCR = 
			[select contactId from OpportunityContactRole where IsPrimary=true and opportunityId in 
				(select Auction_Ticket_OppId__c from CampaignMember where contactId = :idGuest 
					and campaignId = :auctionMaintenance.campaignIdAuctionAttendees) ];
		if (listOCR.size() > 0)
			return listOCR[0].contactId;
		else
			return null;								
	}
	
	// holds the currently selected TicketHolder (Table Captain)
	public ID contactIdTicketHolder { get; set; }

	// callback when the user changes the Table Captain contact lookup.
	public PageReference ChangeTicketHolderLookup() {
		// clear out all state that is specific to the contact
		oppTicket = null;
		listAttendees = null;
		return null;
	}  
	
	// the ticket opportunity for the currently selected Ticket Holder
	public Opportunity oppTicket { 
		get {
			if (oppTicket == null) {	
				// if we have a table captain, look for their ticket first.
				if (contactIdTicketHolder != null) {
					list<Opportunity> listOpp = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount 
						from Opportunity 
						where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
							and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
							and Id in (select OpportunityId from OpportunityContactRole where contactId = :contactIdTicketHolder)];
					if (listOpp.size() > 0) {
						oppTicket = listOpp[0];
						return oppTicket;
					}					
				}
				// if there is no ticket holder, create a new ticket opp.
				oppTicket = new Opportunity(
					RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
					CampaignId = auctionMaintenance.campaignIdAuctionTickets
				);
			} 
			return oppTicket;
		}
		private set; 
	} 
	
	// list for the CampaignMember Status picklist, filtered correctly for statuses for Attendees.
	public list<SelectOption> listSOStatuses {
		get {
			if (listSOStatuses == null) {
				listSOStatuses = new list<SelectOption>();
				
				// since we can't seem to get the styling for a required field for Stage,
				// we won't provide a blank option!
				//listSOStatuses.add(new SelectOption('', ''));

				for (CampaignMemberStatus status : [select Label from CampaignMemberStatus 
					where IsDeleted=false and CampaignId=:auctionMaintenance.campaignIdAuctionAttendees order by SortOrder]) {
					listSOStatuses.add(new SelectOption(status.Label, status.Label));
				}
			}
			return listSOStatuses;
		}
		private set;
	}
		
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public list<Attendee> listAttendees {
    	get {
    		if (listAttendees == null) {
    			listAttendees = new list<Attendee>(); 			
    			
    			// find any existing attendees on this ticket
    			if (oppTicket.Id != null) {
    				
	    			// load up their CM info.
    				 list<CampaignMember> listCM = [select contactId, Id, campaignId, Status, Is_Table_Captain__c, Auction_Ticket_OppId__c,
    					Bid_Number__c, Meal_Preference__c, Paid__c, Table_Captain__c, Table_Name_Number__c
    					from CampaignMember 
    					where Auction_Ticket_OppId__c=:oppTicket.Id];
    			
    				// create a map so we can match CM's with Contacts
    				map<ID, CampaignMember> mapContactIdCM = new map<ID, CampaignMember>();
    				for (CampaignMember cm : listCM) {
    					mapContactIdCM.put(cm.contactId, cm);
    				}    			

	    			// load up their contact info.
	    			list<Contact> listCon = [select Id, FirstName, LastName, Name, MailingStreet, MailingCity,
	    				MailingState, MailingPostalCode, Email, Phone from Contact where Id in :mapContactIdCM.keySet() ];    			
    			
	    			for (Contact con : listCon) {
	    				listAttendees.add(new Attendee(mapContactIdCM.get(con.Id), con));
	    			}
	    			    					
					// create new CampaignMembers for any additional attendees on this ticket    					
		    		double numTickets = oppTicket.Number_Of_Tickets__c;
		    		if (numTickets == null || numTickets == 0) numTickets = 1;
		            for (integer i = listCon.size()+1; i <= numTickets; i++) {
		                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
	                	cmpmbr.Table_Captain__c = contactIdTicketHolder;
	                	cmpmbr.Status = 'RSVP Yes';
	                	cmpmbr.Paid__c = (oppTicket.amount != null);
	                	
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
				attendeeEdit = attendeeFromId(contactIdGuest);				
				// if not loaded (not a current guest), then look it up
				if (attendeeEdit == null) {					
					if (contactIdGuest != null) {
						Contact con = Database.Query('select ' + strContactFields + ' from Contact where Id = :contactIdGuest');
		                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
	                	cmpmbr.Table_Captain__c = contactIdTicketHolder;
	                	cmpmbr.contactId = contactIdGuest;
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
	
	// event handler for NumberOfTickets field being changed.
	// show the appropriate list of attendees by clearing out current state.
	public PageReference OnChange_NumberOfTickets() {
		listAttendees = null;	
		return null;
	}
	
	public PageReference Save() {
		return null;
/*	         
        strSaveResults = 'Starting Save...';
        try {
        	// deal with scenario where user clicks directly on save without
        	// having tabbed out of NumberOfTickets, thus never creating the CampaignMembers.
        	if (listAttendees.size() == 0) {
        		OnChange_NumberOfTickets();
        	}        	
        	
        	// create the opp for the ticket purchase        	
			Contact contact = [select Name, AccountId from Contact where Id=:contactRole.ContactId];	
			opp.Name = contact.Name + ' ' + string.valueof(opp.CloseDate.year()) + AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket;   
			opp.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(AuctionId) * opp.Number_Of_Tickets__c;      	
        	if (opp.amount == null) {
        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
        	} else {
        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;       		
        	}
        	
            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
			// if so, we need to set the Opp's Account to make the rollups work.
			if (AUC_AuctionConstants.isOneToOne()) {
				opp.AccountId = contact.AccountId;
			}
				        	
        	if (opp.Id == null) {
        		insert opp;
				contactRole.OpportunityId = opp.Id;
	        	contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
				contactRole.IsPrimary = true;
				
        	} else {
        		update opp;
        	}
			
			if (contactRole.Id == null) {
				if (AUC_AuctionConstants.fCreateOppContactRoles(opp.Id, contactRole.ContactId)) {				
					insert contactRole;
				}

				// add them to the Tickets campaign.
				CampaignMember cm = new CampaignMember();
				cm.CampaignId = opp.CampaignId;
				cm.ContactId = contactRole.ContactId;
				cm.Status = 'Donated';
				insert cm;
				
			} else {
        		update contactRole;
			}
        		
        	
        	strSaveResults = 'The ticket purchase has been saved.';
        	
			// now create the Attendee CampaignMembers
			list<CampaignMember> listCmpMbrCreate = new list<CampaignMember>();
			list<CampaignMember> listCmpMbrUpdate = new list<CampaignMember>();
			for (CampaignMember cmpmbr : listAttendees) {
				if (cmpmbr.Id != null) {
					listCmpMbrUpdate.add(cmpmbr);					
				} else if (cmpmbr.ContactId != null) {
					cmpmbr.CampaignId = auctionMaintenance.campaignIdAuctionAttendees;
					if (cmpmbr.Bid_Number__c == null) cmpmbr.Bid_Number__c = null;	// force it so updates won't use previous value.
					cmpmbr.Auction_Ticket_OppId__c = opp.id;
					listCmpMbrCreate.add(cmpmbr);
				}
			}
			
			update listCmpMbrUpdate;
			insert listCmpMbrCreate;
			strSaveResults += '  ' + String.valueOf(listCmpMbrCreate.size()) + ' contacts have been added to the auction attendee campaign.';
			if (listCmpMbrUpdate.size() > 0) {
				strSaveResults += '  ' + String.valueOf(listCmpMbrUpdate.size()) + ' contacts have been updated in the auction attendee campaign.'; 
			}	
			
			/* save done, so clear our complete state
			listAttendees = null;							 
			opp = new Opportunity(RecordTypeId=AUC_auctionMaintenance.recordtypeIdAuctionTicket);
			opp.CloseDate = system.Today();
			opp.CampaignId = auctionMaintenance.campaignIdAuctionTickets;
			contactRole = new OpportunityContactRole();
			DECIDED to leave at current info page. /		
			return null;	
			        
        } catch (Exception e) {
        	if (opp.Id == null)
            	strSaveResults = 'Error encountered while trying to save auction ticket purchase and attendees.  ';
            else
            	strSaveResults = 'The ticket purchase has been saved, but errors were encountered trying to save the attendees.  ';
            // strSaveResults += e.getMessage();
            ApexPages.addMessages(e);            
            return null;
        }
*/                
	}

	public PageReference Cancel() {
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
    @RemoteAction global static list<Contact> getListTicketHolders(string auctionId, string strFilter) {
    	strFilter = '%' + strFilter + '%';   	

		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;
		
		set<ID> setContactId = new set<ID>();
		list<Contact> listTicketHolders = new list<Contact>();

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
		
		listTicketHolders = [select Id, Name from Contact where Id in :setContactId	order by Name];		
		return listTicketHolders; 
    } 		

}