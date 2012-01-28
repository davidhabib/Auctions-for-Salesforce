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

	// the current contact search string	
	public string strContactSearch { get; set; }
	
	// the list of contacts that match the search string		
	public list<Contact> listContacts {
		get {
			if (listContacts == null) {
				string strSearch = '%' + strContactSearch + '%';
				listContacts = [select Id, FirstName, LastName, Name, Email, MailingStreet, MailingCity, MailingState, MailingPostalCode, DoNotCall 
					from Contact 
					where Name like :strSearch ];
				// add empty row for new contact
				listContacts.add(new Contact());

				// whenever we refresh the list, select the first contact
				contactId = listContacts[0].Id;
			}
			return listContacts;
		}
		private set;
	}
	
	// holds the currently selected contact from the search list
	public string contactId { get; set; }	// has to be a string to allow a null Id to get returned from the page.	
	
	// holds the currently selected contact from the search list
	public CampaignMember cmGuest { 
		get {
			if (cmGuest == null) {
				cmGuest = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
			}
			return cmGuest;
		}
		private set;
	}
	
	public PageReference selectContact() {
		return null;
	}
	
	public PageReference updateContact() {
		if (contactId == null || contactId == '') {
			Contact con = listContacts[listContacts.size() - 1];
			insert con;
			contactId = con.Id;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'inserted contact: ' + con.Id));
		} else if (contactId != null) {
			Contact con = contactFromId(contactId);
			if (con != null) {
				update con;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'updated contact: ' + con.Id));
			}
		} 
		return null;
	}
	
	// find the contact record for the given Id.
	private Contact contactFromId(ID cId) {
		for (Contact c : listContacts) {
			if (c.Id == cId) {
				return c;
			}
		}
		return null;
	}
	
	// callback when the user changes the contact search.
	public PageReference ChangeContactSearch() {
		// clear out all state that is specific to the contact
		listContacts = null;
		return null;
	}  
		
	// callback when the user changes the Guest Of contact lookup.
	public PageReference ChangeTicketHolderLookup() {
		// clear out all state that is specific to the contact
		oppTicket = null;
		listAttendees = null;
		return null;
	}  

	// object to hold new ticket opportunity
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
				oppTicket = new Opportunity(
					RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
					CampaignId = auctionMaintenance.campaignIdAuctionTickets
				);
			} 
			return oppTicket;
		}
		private set; 
	} 
	
	// holds the currently selected Guest Of contact Id
	public ID contactIdTicketHolder { get; set; }
	
	// list for Status picklist, filtered correctly for statuses for Attendees.
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
	
	// the list of ticket holders
	public list<SelectOption> listSOTicketHolders{
		get {
			if (listSOTicketHolders != null) return listSOTicketHolders;
			listSOTicketHolders = new list<SelectOption>();
			listSOTicketHolders.add(new SelectOption('', '(none)'));

			// use a set to avoid dups
			set<ID> setContactId = new set<ID>();
			set<ID> setContactId2 = new set<ID>();

			// in one soql call, get all the appropriate opportunities for auction tickets
			for (list<OpportunityContactRole> listOCR : [select contactId, contact.Name from OpportunityContactRole 
				where IsPrimary=true and 
					(opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets) 
				order by contact.Name]) {
				
				for (OpportunityContactRole ocr : listOCR) {
					if (setContactId.contains(ocr.contactId) || setContactId2.contains(ocr.contactId))
						continue;
					if (setContactId.size() < 999 && setContactId.add(ocr.contactId)) {
						listSOTicketHolders.add(new SelectOption(ocr.contactId, ocr.Contact.Name));
					} else if (setContactId2.add(ocr.contactId)) {
						if (listSOTicketHolders2 == null) listSOTicketHolders2 = new list<SelectOption>();
						listSOTicketHolders2.add(new SelectOption(ocr.contactId, ocr.Contact.Name));						
					}
				}
			}		

			return listSOTicketHolders;
		}
		set;
	}	

	// in order to support lists of TicketHolders > 1000, we need a second list.
	public list<SelectOption> listSOTicketHolders2 { get; set; }
	
	//==================== Attendee Class ======================================
	// helper class that holds a contact, and their campaign member
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

	public Attendee attendeeEdit { 
		get {
			if (attendeeEdit == null) {
				attendeeEdit = new Attendee();
			}
			return attendeeEdit; 
		}
		private set;
	}
			
	// callback when the user changes the current auction in the dropdown.
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		oppTicket.CampaignId = auctionMaintenance.campaignIdAuctionTickets;
		strSaveResults = null;
		contactIdTicketHolder = null;
		oppTicket = null;
		listAttendees = null;	
		listSOTicketHolders = null;
		listSOTicketHolders2 = null;
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

	
	//==================== TEST METHOD(s) ======================================
	public static testmethod void CodeCoverageTests() {
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction; 
		System.Assert(auction.id != null); 	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	
    	Account acc = new Account(Name='My Test Account');
    	insert acc;
    	
    	Contact contact = new Contact(
    		Firstname = 'Johnny',
    		Lastname = 'Test',
    		AccountId = acc.Id
    	);
    	insert contact;    	

		//point to our VF page
		PageReference p = new PageReference('Page.AuctionCheckIn3');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionCheckIn3 ctrl = new AUC_CTRL_AuctionCheckIn3();
		ctrl.ChangeAuction();
		//ctrl.contactRole.ContactId = contact.id;
		System.AssertEquals(campaign.Id, ctrl.oppTicket.CampaignId);
		System.AssertEquals(System.Today(), ctrl.oppTicket.CloseDate);
		ctrl.oppTicket.Amount = 15;
		ctrl.oppTicket.Number_Of_Tickets__c = 4;
		ctrl.OnChange_NumberOfTickets();
		System.AssertEquals(4, ctrl.listAttendees.size());
		System.AssertEquals(contact.Id, ctrl.listAttendees[0].cm.ContactId);
		ctrl.Save();
		System.Assert(ctrl.oppTicket.id != null);
		System.AssertEquals('The ticket purchase has been saved.  1 contacts have been added to the auction attendee campaign.', ctrl.strSaveResults);

		// now test editing an existing ticket opp
		//point to our VF page
		p = new PageReference('Page.AuctionCheckIn3');
		p.getParameters().put('auctionId', auction.id); 
		p.getParameters().put('oppId', ctrl.oppTicket.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		ctrl = new AUC_CTRL_AuctionCheckIn3();
		ctrl.ChangeAuction();
		//ctrl.contactRole.ContactId = contact.id;
		//System.AssertEquals(contact.Id, ctrl.contactRole.ContactId);
		System.AssertEquals(campaign.Id, ctrl.oppTicket.CampaignId);
		System.AssertEquals(System.Today(), ctrl.oppTicket.CloseDate);
		ctrl.oppTicket.Amount = 25;
		ctrl.oppTicket.Number_Of_Tickets__c = 6;
		ctrl.OnChange_NumberOfTickets();
		System.AssertEquals(6, ctrl.listAttendees.size());
		System.AssertEquals(contact.Id, ctrl.listAttendees[0].cm.ContactId);
		ctrl.Save();
		System.AssertEquals('The ticket purchase has been saved.  0 contacts have been added to the auction attendee campaign.  1 contacts have been updated in the auction attendee campaign.', ctrl.strSaveResults);
		ctrl.Cancel();
	}
	
    static testMethod void UnitTestNullAuction() {
    	// delete all auctions first
    	delete [select Id from Auction__c];
    
    	//point to our VF page
    	PageReference page = new PageReference('Page.AuctionCheckIn3');
    	page.getParameters().put('auctionId', 'null');
		Test.setCurrentPageReference(page);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionCheckIn3 ctrl = new AUC_CTRL_AuctionCheckIn3();
		System.AssertEquals(null, ctrl.auctionId);
		System.AssertEquals(1, ctrl.listSOAuctions.size());
		System.AssertEquals(0, ctrl.listAttendees.size());
		ctrl.Cancel();  
    }	
}