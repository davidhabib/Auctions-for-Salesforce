// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewTicketWizard { 

	// constructor for the class
	public AUC_CTRL_AuctionNewTicketWizard() {
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');
		
		// do any initialization which is not dependent on having an auctionId
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;	
		
		// create a new opp, or load existing opp if passed in
		String strOppId = ApexPages.currentPage().getParameters().get('oppId');	
		if (strOppId != null && strOppId != '') {
			opp = [select accountId, campaignId, CloseDate, Number_Of_Tickets__c, Description, Name, StageName, Amount 
					from Opportunity where Id=:strOppId];
					
			// handle a non-existant contact role.
			list<OpportunityContactRole> listCR = new list<OpportunityContactRole>();
			listCR = [select contactId, OpportunityId, Role, IsPrimary from OpportunityContactRole
					where OpportunityId=:opp.Id and IsPrimary=true];
			if (listCR.size() > 0) {		
				contactRole = listCR[0];
			} else {
				contactRole = new OpportunityContactRole();	
				contactRole.OpportunityId = opp.Id;
	        	contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
				contactRole.IsPrimary = true;				
			} 	
							
			// always use the correct auctionId.  Don't rely on what's passed in.
			if (opp.campaignId != null) {
				Campaign cmp = [select Auction__c from Campaign where Id=:opp.CampaignId];
				auctionId = cmp.Auction__c;
				auctionMaintenance.auctionId = auctionId;				
			}
		} else {
			opp = new Opportunity(RecordTypeId=AUC_auctionMaintenance.recordtypeIdAuctionTicket);
			opp.CloseDate = system.Today();
			contactRole = new OpportunityContactRole();			
				
			// use auctionId passed in if there, else use latest auction.
			if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
				auctionId = strAuctionId;
			} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
				auctionId = listSOAuctions[1].getValue();
			}	
			auctionMaintenance.auctionId = auctionId;
			opp.CampaignId = auctionMaintenance.campaignIdAuctionTickets;				
		}
	}

	private AUC_AuctionMaintenance auctionMaintenance;
		
	// the currently selected Auction
	public Id auctionId { get; set; }
		
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }
		
	// object to hold opportunity
	public Opportunity opp { get; set; } 
	
	// we instantiate this object to get the Contact lookup field. We also will save it.
	public OpportunityContactRole contactRole { get; set; }
	
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
	
	// list for Stage picklist, filtered correctly for stages for Auction Donated Item opps.
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
		
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public list<CampaignMember> listCmpMbrAttendees {
    	set;
    	
    	get {
    		double numTickets = opp.Number_Of_Tickets__c;
    		if (listCmpMbrAttendees == null) {
    			listCmpMbrAttendees = new list<CampaignMember>(); 			
    			
    			// find any existing attendees on this ticket
    			if (opp.Id != null) {
    				listCmpMbrAttendees = [select Id, campaignId, contactId, Status, Is_Table_Captain__c, Auction_Ticket_OppId__c,
    					Bid_Number__c, Meal_Preference__c, Paid__c, Table_Captain__c, Table_Name_Number__c, Note__c 
    					from CampaignMember 
    					where Auction_Ticket_OppId__c=:opp.Id];
    			}
    			    					
				// create new CampaignMembers for any additional attendees on this ticket    					
	            for (integer i = listCmpMbrAttendees.size()+1; i <= numTickets; i++) {
	                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                	cmpmbr.Table_Captain__c = contactRole.contactId;
                	cmpmbr.Status = 'RSVP Yes';
                	cmpmbr.Paid__c = (opp.amount != null);
	                // add the ticket purchaser as the first attendee
	                if (i == 1) {
	                	cmpmbr.contactId = contactRole.contactId;
	                	cmpmbr.Is_Table_Captain__c = true;
	                } 
	                listCmpMbrAttendees.add(cmpmbr);
	            }
	        }
	        return listCmpMbrAttendees;
    	}
    } 	

	// callback when the user changes the current auction in the dropdown.
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;
		opp.CampaignId = auctionMaintenance.campaignIdAuctionTickets;
		strSaveResults = null;
		return null;
	}  

	// status string for reporting the results of saving.
    public String strSaveResults { get; set; }    
	
	// event handler for NumberOfTickets field being changed.
	// show the appropriate list of attendees by clearing out current state.
	public PageReference OnChange_NumberOfTickets() {
		listCmpMbrAttendees.clear();
		listCmpMbrAttendees = null;	
		return null;
	}
	
	private class MySaveException extends Exception {}
	
	public PageReference Save() {
        strSaveResults = 'Starting Save...';
	        
        try {
        	// deal with scenario where user clicks directly on save without
        	// having tabbed out of NumberOfTickets, thus never creating the CampaignMembers.
        	if (listCmpMbrAttendees.size() == 0) {
        		OnChange_NumberOfTickets();
        	}        	
        	
        	// create or update the opp for the ticket purchase
        	// verify that either contact or account is specified, but don't require both.
        	if (contactRole.ContactId == null && opp.AccountId == null) {
        		throw(new MySaveException('Please specify a Contact or an Account.'));
        	}
        	
        	// name the opp if empty (new scenario)
        	if (opp.Name == null) {
        		string strTicketOwner;
	        	if (opp.AccountId != null) {
	        		Account acc = [select Id, Name from Account where Id = :opp.AccountId];
					strTicketOwner = acc.Name; 
	        	} else if (contactRole.ContactId != null) {
					Contact contact = [select Name, AccountId from Contact where Id=:contactRole.ContactId];
					strTicketOwner = contact.Name;

		            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
					// if so, we need to set the Opp's Account to make the rollups work.
					if (AUC_AuctionConstants.isOneToOne() && opp.AccountId == null) {
						opp.AccountId = contact.AccountId;
					}
	        	}
	        	opp.Name = strTicketOwner + ' ' + string.valueof(opp.CloseDate.year()) + AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket;
        	}        	
 
			opp.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(AuctionId) * opp.Number_Of_Tickets__c;     
			if (opp.StageName == null) { 	
	        	if (opp.amount == null) {
	        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
	        	} else {
	        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;       		
	        	}
			}
			        	
			// save the ticket opp			        					        		
        	if (opp.Id == null) {
        		insert opp;
				contactRole.OpportunityId = opp.Id;
	        	contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
				contactRole.IsPrimary = true;				
        	} else {
        		update opp;
        	}
			
			// if creating a new contact role, then also put the contact on the Tickets campaign.
			if (contactRole.Id == null) {
				if (AUC_AuctionConstants.fCreateOppContactRoles(opp.Id, contactRole.ContactId)) {				
					insert contactRole;
				}
				// add them to the Tickets campaign.
				if (contactRole.ContactId != null) {
					CampaignMember cm = new CampaignMember();
					cm.CampaignId = opp.CampaignId;
					cm.ContactId = contactRole.ContactId;
					cm.Status = 'Donated';
					insert cm;
				}				
			} else {
        		update contactRole;
			}
        		       	
        	strSaveResults = 'The ticket purchase has been saved.';
        	
			// now create the Attendee CampaignMembers
			list<CampaignMember> listCmpMbrCreate = new list<CampaignMember>();
			list<CampaignMember> listCmpMbrUpdate = new list<CampaignMember>();
			for (CampaignMember cmpmbr : listCmpMbrAttendees) {
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
			listCmpMbrAttendees = null;							 
			opp = new Opportunity(RecordTypeId=AUC_auctionMaintenance.recordtypeIdAuctionTicket);
			opp.CloseDate = system.Today();
			opp.CampaignId = auctionMaintenance.campaignIdAuctionTickets;
			contactRole = new OpportunityContactRole();
			DECIDED to leave at current info page. */		
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
		PageReference p = new PageReference('Page.AuctionNewTicketWizard');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewTicketWizard ctrl = new AUC_CTRL_AuctionNewTicketWizard();
		ctrl.ChangeAuction();
		ctrl.contactRole.ContactId = contact.id;
		System.AssertEquals(campaign.Id, ctrl.opp.CampaignId);
		System.AssertEquals(System.Today(), ctrl.opp.CloseDate);
		ctrl.opp.Amount = 15;
		ctrl.opp.Number_Of_Tickets__c = 4;
		ctrl.OnChange_NumberOfTickets();
		System.AssertEquals(4, ctrl.listCmpMbrAttendees.size());
		System.AssertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
		ctrl.Save();
		System.Assert(ctrl.opp.id != null);
		System.AssertEquals('The ticket purchase has been saved.  1 contacts have been added to the auction attendee campaign.', ctrl.strSaveResults);

		// now test editing an existing ticket opp
		//point to our VF page
		p = new PageReference('Page.AuctionNewTicketWizard');
		p.getParameters().put('auctionId', auction.id); 
		p.getParameters().put('oppId', ctrl.opp.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		ctrl = new AUC_CTRL_AuctionNewTicketWizard();
		ctrl.ChangeAuction();
		//ctrl.contactRole.ContactId = contact.id;
		System.AssertEquals(contact.Id, ctrl.contactRole.ContactId);
		System.AssertEquals(campaign.Id, ctrl.opp.CampaignId);
		System.AssertEquals(System.Today(), ctrl.opp.CloseDate);
		ctrl.opp.Amount = 25;
		ctrl.opp.Number_Of_Tickets__c = 6;
		ctrl.OnChange_NumberOfTickets();
		System.AssertEquals(6, ctrl.listCmpMbrAttendees.size());
		System.AssertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
		ctrl.Save();
		System.AssertEquals('The ticket purchase has been saved.  0 contacts have been added to the auction attendee campaign.  1 contacts have been updated in the auction attendee campaign.', ctrl.strSaveResults);
		ctrl.Cancel();
	}
	
    static testMethod void UnitTestNullAuction() {
    	// delete all auctions first
    	delete [select Id from Auction__c];
    
    	//point to our VF page
    	PageReference page = new PageReference('Page.AuctionNewTicketWizard');
    	page.getParameters().put('auctionId', 'null');
		Test.setCurrentPageReference(page);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewTicketWizard ctrl = new AUC_CTRL_AuctionNewTicketWizard();
		System.AssertEquals(null, ctrl.auctionId);
		System.AssertEquals(1, ctrl.listSOAuctions.size());
		System.AssertEquals(0, ctrl.listCmpMbrAttendees.size());
		ctrl.Cancel();  
    }	
}