// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewTicketWizard { 

	// constructor for the class
	public AUC_CTRL_AuctionNewTicketWizard() {
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
		
		// do any initialization which is not dependent on having an auctionId
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;	
		
		// create a new opp, or load existing opp if passed in
		String strOppId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('oppId'));	
		if (strOppId != null && strOppId != '') {
			opp = Database.Query('select ' + strOppFields +	' from Opportunity where Id = :strOppId');
			
			// put payment info in our temp fields
			if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
				strPaymentMethod = string.valueOf(opp.get(AUC_AuctionConstants.strOppPaymentMethodField));
			} else {
				strPaymentMethod = AUC_AuctionMaintenance.strPaymentMethodOrCheckFromNPSPPayments(opp.Id, false);
			}
			if (AUC_AuctionConstants.strOppCheckNumberField != null) {
				strCheckNumber = string.valueOf(opp.get(AUC_AuctionConstants.strOppCheckNumberField));
			} else {
				strCheckNumber = AUC_AuctionMaintenance.strPaymentMethodOrCheckFromNPSPPayments(opp.Id, true);
			}
			
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
			
			// set the per ticket deductible FMV
			if (opp.Number_Of_Tickets__c != null && opp.Auction_Non_Deductible_Amount__c != null)
				decTicketFMV = opp.Auction_Non_Deductible_Amount__c / opp.Number_Of_Tickets__c;
			else
				decTicketFMV = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auctionId);

		} else {
			opp = new Opportunity(RecordTypeId=AUC_auctionMaintenance.recordtypeIdAuctionTicket);
			opp.CloseDate = system.Today();
			opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;  // assume new tickets are going in as paid.
			contactRole = new OpportunityContactRole();			
				
			// use auctionId passed in if there, else use latest auction.
			if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
				auctionId = strAuctionId;
			} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
				auctionId = listSOAuctions[1].getValue();
			}	
			auctionMaintenance.auctionId = auctionId;
			opp.CampaignId = auctionMaintenance.campaignIdAuctionTickets;				
			decTicketFMV = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auctionId);
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
	
	// the per ticket FMV to use
	public decimal decTicketFMV { get; set; }
	
	// helper routine to return all Opportunity field names from the Field Set
	private string strOppFields {
		get {
			if (strOppFields == null) {
				strOppFields = AUC_AuctionMaintenance.strFieldNamesFromFieldSet('Opportunity', 'GW_Auctions__AuctionNewTicketWizardFS');

				// make sure Name field is included.
				if (!strOppFields.contains(' Name,')) strOppFields += ', Name';

				// make sure Number Of Tickets field is included.
				if (!strOppFields.contains(' Number_of_Tickets__c,')) strOppFields += ', Number_of_Tickets__c';

				// make sure Non Deductible Amount field is included.
				if (!strOppFields.contains(' Auction_Non_Deductible_Amount__c,')) strOppFields += ', Auction_Non_Deductible_Amount__c';

				if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
					if (!strOppFields.contains(AUC_AuctionConstants.strOppPaymentMethodField)) strOppFields += ', ' + AUC_AuctionConstants.strOppPaymentMethodField; 
				}
				if (AUC_AuctionConstants.strOppCheckNumberField != null) {
					if (!strOppFields.contains(AUC_AuctionConstants.strOppCheckNumberField)) strOppFields += ', ' + AUC_AuctionConstants.strOppCheckNumberField; 
				}					
			}
			return strOppFields;
		}
		set;
	}
		
	// helper routine to return all CampaignMember field names from the Field Set
	private string strCMFields {
		get {
			if (strCMFields == null) {
				strCMFields = AUC_AuctionMaintenance.strFieldNamesFromFieldSet('CampaignMember', 'GW_Auctions__AuctionNewTicketWizardFS');
			}
			return strCMFields;
		}
		set;
	}
		
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
	
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public list<CampaignMember> listCmpMbrAttendees {
    	set;
    	
    	get {
    		double numTickets = opp.Number_Of_Tickets__c;
    		if (listCmpMbrAttendees == null) {
    			listCmpMbrAttendees = new list<CampaignMember>(); 			
    			
    			// find any existing attendees on this ticket
    			if (opp.Id != null) {
    				listCmpMbrAttendees = Database.Query('select ' + strCMFields +	
    					' from CampaignMember where Auction_Ticket_OppId__c=\'' + opp.Id + '\''); 
    			}
    			    					
				// create new CampaignMembers for any additional attendees on this ticket    					
	            for (integer i = listCmpMbrAttendees.size()+1; i <= numTickets; i++) {
	                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                	cmpmbr.Table_Captain__c = contactRole.contactId;
                	cmpmbr.Status = 'RSVP Yes';
                	cmpmbr.Paid__c = (opp.amount != null);
	                // add the ticket purchaser as the first attendee
	                if (i == 1) {
	                	// but make sure they aren't already an attendee
	                	list<CampaignMember> listCmpMbr = [select Id from CampaignMember
	                		where CampaignId = :cmpmbr.CampaignId and ContactId = :contactRole.contactId];
	                	if (listCmpMbr.size() == 0) {	                	
		                	cmpmbr.contactId = contactRole.contactId;
		                	cmpmbr.Is_Table_Captain__c = true;
	                	}
	                } 
	                listCmpMbrAttendees.add(cmpmbr);
	            }
	        }
	        return listCmpMbrAttendees;
    	}
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
	
	// will hold the ID of the CM to be deleted
	public ID idDeleteCM { get; set; }
	
	// action method to delete a CM from the database.
	public PageReference DeleteCM() {
		if (idDeleteCM != null) {
			database.delete(idDeleteCM);
			idDeleteCM = null;
			listCmpMbrAttendees = null;
		}
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
        		throw(new MySaveException('Please specify a Contact or ' + SObjectType.Account.Label));
        	}
        	
        	// name the opp if empty (new scenario)
        	if (opp.Name == null) {
	            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
				// if so, we need to set the Opp's Account to make the rollups work.
	        	if (opp.AccountId == null && contactRole.ContactId != null && AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
					Contact contact = [select AccountId from Contact where Id=:contactRole.ContactId];
					opp.AccountId = contact.AccountId;
				}
	        	opp.Name = auctionMaintenance.StrOppTicketName(opp.accountId, contactRole.contactId);
        	}        	
 
			opp.Auction_Non_Deductible_Amount__c = decTicketFMV * opp.Number_Of_Tickets__c;
			if (opp.StageName == null) { 	
	        	if (opp.amount == null) {
	        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
	        	} else {
	        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;       		
	        	}
			}
			
			if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
				opp.put(AUC_AuctionConstants.strOppPaymentMethodField, strPaymentMethod);
			}
			if (AUC_AuctionConstants.strOppCheckNumberField != null && strPaymentMethod == 'Check') {
				opp.put(AUC_AuctionConstants.strOppCheckNumberField, strCheckNumber);
			}					
			        	
			// save the ticket opp	
        	if (opp.Id == null) {
        		AUC_AuctionMaintenance.didUpdateOppWithNPSPOCRData(opp, contactRole.ContactId);
        		insert opp;
				contactRole.OpportunityId = opp.Id;
	        	contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
				contactRole.IsPrimary = true;				
        	} else {
        		update opp;
        	}
        	
			// if using NPSP Payments, update payment info.
			AUC_AuctionMaintenance.UpdateNPSPPayments(new list<Opportunity> { opp }, strPaymentMethod, strCheckNumber);        	
			
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
					// note that they may already be on the tickets campaign.
					try {
						insert cm;
					} catch (Exception ex) {
						// silently handle.
					}
				}				
			} else {
        		update contactRole;
			}
        		       	
        	strSaveResults = 'The ticket purchase has been saved.';
        	
			// now create the Attendee CampaignMembers
			list<CampaignMember> listCmpMbrCreate = new list<CampaignMember>();
			list<CampaignMember> listCmpMbrUpdate = new list<CampaignMember>();
			set<ID> setContactIdCreate = new set<ID>();
			
			for (CampaignMember cmpmbr : listCmpMbrAttendees) {
				if (cmpmbr.Id != null) {
					listCmpMbrUpdate.add(cmpmbr);					
				} else if (cmpmbr.ContactId != null) {
					cmpmbr.CampaignId = auctionMaintenance.campaignIdAuctionAttendees;
					if (cmpmbr.Bid_Number__c == null) cmpmbr.Bid_Number__c = null;	// force it so updates won't use previous value.
					cmpmbr.Auction_Ticket_OppId__c = opp.id;
					listCmpMbrCreate.add(cmpmbr);
					setContactIdCreate.add(cmpmbr.ContactId);
				}
			}
			
			update listCmpMbrUpdate;

			// before inserting new CM's, make sure the contacts weren't already on the Attendees campaign.
			// if they were, go ahead and delete their previous CM, and save their new CM.
			list<CampaignMember> listCmpMbrDelete = new list<CampaignMember>();
			listCmpMbrDelete = [select Id from CampaignMember where CampaignId = :auctionMaintenance.campaignIdAuctionAttendees
				and ContactId in :setContactIdCreate];
			delete listCmpMbrDelete;
			// now it is safe to add them			 
			insert listCmpMbrCreate;
			
			strSaveResults += '  ' + String.valueOf(listCmpMbrCreate.size()) + ' contacts have been added to the auction attendee campaign.';
			if (listCmpMbrUpdate.size() > 0) {
				strSaveResults += '  ' + String.valueOf(listCmpMbrUpdate.size()) + ' contacts have been updated in the auction attendee campaign.'; 
			}	
			
			// assume they already charged the card, and we don't want the page refresh to reload the payment terminal.
			fShowPanelCreditCard = false;					
			return null;	
			        
        } catch (Exception e) {
        	if (opp.Id == null)
            	strSaveResults = 'Error encountered while trying to save auction ticket purchase and attendees.  ';
            else
            	strSaveResults = 'The ticket purchase has been saved, but errors were encountered trying to save the attendees.  ';
            ApexPages.addMessages(e);            

			// assume they already charged the card, and we don't want the page refresh to reload the payment terminal.
			fShowPanelCreditCard = false;
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
	
	public PageReference SaveAndClose() {
		Save();
		// now see if there was an error
		if (ApexPages.hasMessages()) {
			return null;
		} else {
			return Cancel();
		}
	}
	
	//==================== Support for Payment Processing ======================================
	
	// public property on whether to display the credit card panel
	public boolean fShowPanelCreditCard { get; set; }
	
	// public method to show the credit card panel
	public PageReference ShowPanelCreditCard() {
		fShowPanelCreditCard = true;
		strPaymentMethod = 'Credit Card';
		return null;
	}

	public string strPaymentMethod { get; set; }
	public string strCheckNumber { get; set; }
	
	// public method called by the page when the Payment Method changes
	public PageReference ChangePaymentMethod() {
		// new value will be in strPaymentMethod
		fShowPanelCreditCard = false;
		return null;
	}		

	// public property to get the commandButton URL
	// for the Charge Credit Card button.	
	public string strCreditCardChargeURL {
		get {
			//if (strCreditCardChargeURL == null && contactRole.contactId != null) {
			// always recompute, because we don't have callback when contactRole.contactId or opp.Amount changes.
			{ 
				string str = AUC_AuctionConstants.StrCreditCardChargeURLFormula();
				if (str != null) {
					// {0} = contactId
					// {1} = auctionId
					// {2} = amount		
					// {3} = sessionId
					// {4} = partner server url
					// {5} = organizationId
					list<string> listFormat = new list<string>();
					listFormat.add(contactRole.contactId);
					listFormat.add(auctionId);
					listFormat.add(string.valueOf(opp.Amount));
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
	
	// property to tell whether there is no place to store the Payment Method 
	public boolean isPaymentSettingsMissing {
		get {
			return AUC_AuctionConstants.isPaymentSettingsMissing;
		}
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
		ctrl.contactRole.ContactId = contact.id;
		System.AssertEquals(campaign.Id, ctrl.opp.CampaignId);
		System.AssertEquals(System.Today(), ctrl.opp.CloseDate);
		ctrl.opp.Amount = 15;
		ctrl.opp.Number_Of_Tickets__c = 4;
		ctrl.OnChange_NumberOfTickets();
		System.AssertEquals(4, ctrl.listCmpMbrAttendees.size());
		System.AssertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
		ctrl.ChangePaymentMethod();
		ctrl.ShowPanelCreditCard();
		system.assertEquals(true, ctrl.fShowPanelCreditCard);
		system.assertEquals('Credit Card', ctrl.strPaymentMethod);
		system.assertEquals(null, ctrl.strCheckNumber);
		system.assertEquals(null, ctrl.strCreditCardChargeURL);
		system.assertNotEquals(null, ctrl.strPaymentProcessorWindowParameters);
		system.assertEquals(false, ctrl.fShowPaymentProcessorOnPage);
		system.assertNotEquals(null, ctrl.strPaymentProcessorPageHeight);
		
		ctrl.Save();
		System.Assert(ctrl.opp.id != null);
		System.AssertEquals('The ticket purchase has been saved.  1 contacts have been added to the auction attendee campaign.', ctrl.strSaveResults);
		list<Opportunity> listOpp = [select Id, Name, Amount from Opportunity];
		system.assertEquals(1, listOpp.size());
		list<OpportunityContactRole> listOCR = [select Id, ContactId from OpportunityContactRole where isPrimary=true];
		system.assertEquals(1,listOCR.size());
		system.assertEquals(contact.Id, listOCR[0].ContactId);

		// now test editing an existing ticket opp
		//point to our VF page
		p = new PageReference('Page.AuctionNewTicketWizard');
		p.getParameters().put('auctionId', auction.id); 
		p.getParameters().put('oppId', ctrl.opp.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		ctrl = new AUC_CTRL_AuctionNewTicketWizard();
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