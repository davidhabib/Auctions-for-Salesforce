// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewTicketWizard { 

	// constructor for the class
	public AUC_CTRL_AuctionNewTicketWizard() {

		checkFLS();

		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a String to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
		
		// do any initialization which is not dependent on having an auctionId
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;	
		
		// create a new opp, or load existing opp if passed in
		String strOppId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('oppId'));	
		if (strOppId != null && strOppId != '') {
			opp = Database.query('SELECT ' + String.join(new List<String>(setOppFields), ',') +	' FROM Opportunity WHERE Id = :strOppId');
			
			// put payment info in our temp fields
			if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
				strPaymentMethod = String.valueOf(opp.get(AUC_AuctionConstants.strOppPaymentMethodField));
			} else {
				strPaymentMethod = AUC_AuctionMaintenance.strPaymentMethodOrCheckFromNPSPPayments(opp.Id, false);
			}
			if (AUC_AuctionConstants.strOppCheckNumberField != null) {
				strCheckNumber = String.valueOf(opp.get(AUC_AuctionConstants.strOppCheckNumberField));
			} else {
				strCheckNumber = AUC_AuctionMaintenance.strPaymentMethodOrCheckFromNPSPPayments(opp.Id, true);
			}
			
			// handle a non-existant contact role.
			List<OpportunityContactRole> listCR = new List<OpportunityContactRole>();
			listCR = [SELECT ContactId, OpportunityId, Role, IsPrimary FROM OpportunityContactRole
					WHERE OpportunityId=:opp.Id AND IsPrimary=TRUE];
			if (listCR.size() > 0) {		
				contactRole = listCR[0];
			} else {
				contactRole = new OpportunityContactRole();	
				contactRole.OpportunityId = opp.Id;
	        	contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
				contactRole.IsPrimary = true;				
			} 	
							
			// always use the correct auctionId.  Don't rely on what's passed in.
			if (opp.CampaignId != null) {
				Campaign cmp = [SELECT Auction__c FROM Campaign WHERE Id=:opp.CampaignId];
				auctionId = cmp.Auction__c;
				auctionMaintenance.auctionId = auctionId;				
			}
			
			// set the per ticket deductible FMV
			if (opp.Number_of_Tickets__c != null && opp.Number_of_Tickets__c > 0 && opp.Auction_Non_Deductible_Amount__c != null) {
				decTicketFMV = opp.Auction_Non_Deductible_Amount__c / opp.Number_of_Tickets__c;
			} else {
				decTicketFMV = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auctionId);
			}

		} else {
			opp = new Opportunity(RecordTypeId=AUC_AuctionMaintenance.recordtypeIdAuctionTicket);
			opp.CloseDate = System.today();
			AUC_AuctionMaintenance.setOpportunityStageClosed(opp); // assume new tickets are going in as paid.
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

	// check Field Level Security and object permissions on all objects and fields this page uses
	private void checkFLS() {
		UTIL_Describe.checkCreateAccess('Opportunity', setOppFields);
		UTIL_Describe.checkUpdateAccess('Opportunity', setOppFields);

		UTIL_Describe.checkCreateAccess('CampaignMember', setCMFields);
		setCMFields.remove('ContactId');
		UTIL_Describe.checkUpdateAccess('CampaignMember', setCMFields);
		setCMFields.add('ContactId');
		UTIL_Describe.checkObjectDeleteAccess('CampaignMember');
	}

	private AUC_AuctionMaintenance auctionMaintenance;
		
	// the currently selected Auction
	public Id auctionId { get; set; }
		
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions { get; set; }
		
	// object to hold opportunity
	public Opportunity opp { get; set; } 
	
	// we instantiate this object to get the Contact lookup field. We also will save it.
	public OpportunityContactRole contactRole { get; set; }
	
	// the per ticket FMV to use
	public Decimal decTicketFMV { get; set; }

	private Set<String> setOppFields {
		get {
			if (setOppFields == null) {
				setOppFields = AUC_AuctionMaintenance.setFieldNamesFromFieldSet('Opportunity',
					UTIL_Describe.StrTokenNSPrefix('AuctionNewTicketWizardFS'));
				setOppFields.add('Name');
				setOppFields.add(UTIL_Describe.StrTokenNSPrefix('Number_of_Tickets__c'));
				setOppFields.add(UTIL_Describe.StrTokenNSPrefix('Auction_Non_Deductible_Amount__c'));
				if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
					setOppFields.add(AUC_AuctionConstants.strOppPaymentMethodField);
				}
				if (AUC_AuctionConstants.strOppCheckNumberField != null) {
					setOppFields.add(AUC_AuctionConstants.strOppCheckNumberField);
				}
			}
			return setOppFields;
		}
		set;
	}

	private Set<String> setCMFields {
		get {
			if (setCMFields == null) {
				setCMFields = AUC_AuctionMaintenance.setFieldNamesFromFieldSet('CampaignMember',
					UTIL_Describe.StrTokenNSPrefix('AuctionNewTicketWizardFS'));
			}
			return setCMFields;
		}
		set;
	}

	// list for Status picklist, filtered correctly for statuses for Attendees.
	public List<SelectOption> listSOStatuses {
		get {
			if (listSOStatuses == null) {
				listSOStatuses = new List<SelectOption>();
				
				// since we can't seem to get the styling for a required field for Stage,
				// we won't provide a blank option!
				//listSOStatuses.add(new SelectOption('', ''));

				for (CampaignMemberStatus status : [SELECT Label FROM CampaignMemberStatus 
					WHERE IsDeleted=FALSE AND CampaignId=:auctionMaintenance.campaignIdAuctionAttendees ORDER BY SortOrder]) {
					listSOStatuses.add(new SelectOption(status.Label, status.Label));
				}
			}
			return listSOStatuses;
		}
		private set;
	}
	
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
	// since displayed with apex:inputFields, no need to check FLS here
    public List<CampaignMember> listCmpMbrAttendees {
    	get {
    		Double numTickets = opp.Number_of_Tickets__c;
    		if (listCmpMbrAttendees == null) {
    			listCmpMbrAttendees = new List<CampaignMember>(); 			
    			
    			// find any existing attendees on this ticket
    			if (opp.Id != null) {
    				listCmpMbrAttendees = Database.query('SELECT ' + String.join(new List<String>(setCMFields), ',') +
    					' FROM CampaignMember WHERE Auction_Ticket_OppId__c=\'' + opp.Id + '\''); 
    			}
    			    					
				// create new CampaignMembers for any additional attendees on this ticket    					
	            for (Integer i = listCmpMbrAttendees.size()+1; i <= numTickets; i++) {
	                CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                	cmpmbr.Table_Captain__c = contactRole.ContactId;
                	cmpmbr.Status = 'RSVP Yes';
                	cmpmbr.Paid__c = (opp.Amount != null);
	                // add the ticket purchaser as the first attendee
	                if (i == 1) {
	                	// but make sure they aren't already an attendee
	                	List<CampaignMember> listCmpMbr = [SELECT Id FROM CampaignMember
	                		WHERE CampaignId = :cmpmbr.CampaignId AND ContactId = :contactRole.ContactId];
	                	if (listCmpMbr.size() == 0) {	                	
		                	cmpmbr.ContactId = contactRole.ContactId;
		                	cmpmbr.Is_Table_Captain__c = true;
	                	}
	                } 
	                listCmpMbrAttendees.add(cmpmbr);
	            }
	        }
	        return listCmpMbrAttendees;
    	}
	    private set;
    }

	// status String for reporting the results of saving.
    public String strSaveResults { get; set; }    
	
	// event handler for NumberOfTickets field being changed.
	// show the appropriate list of attendees by clearing out current state.
	public PageReference OnChange_NumberOfTickets() {
		listCmpMbrAttendees.clear();
		listCmpMbrAttendees = null;	
		return null;
	}
	
	// will hold the ID of the CM to be deleted
	public Id idDeleteCM { get; set; }
	
	// action method to delete a CM FROM the database.
	public PageReference DeleteCM() {
		try {
			if (idDeleteCM != null) {
				Database.delete(idDeleteCM);
				idDeleteCM = null;
				listCmpMbrAttendees = null;
			}
			return null;
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
			return null;
		}
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
        		throw(new MySaveException('Please specify a Contact or ' + SObjectType.Account.label));
        	}
        	
        	// name the opp if empty (new scenario)
        	if (opp.Name == null) {
	            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
				// if so, we need to set the Opp's Account to make the rollups work.
	        	if (opp.AccountId == null && contactRole.ContactId != null && AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
					Contact contact = [SELECT AccountId FROM Contact WHERE Id=:contactRole.ContactId];
					opp.AccountId = contact.AccountId;
				}
	        	opp.Name = auctionMaintenance.StrOppTicketName(opp.AccountId, contactRole.ContactId);
        	}        	
 
			opp.Auction_Non_Deductible_Amount__c = decTicketFMV * opp.Number_of_Tickets__c;
			if (opp.StageName == null) { 	
	        	if (opp.Amount == null) {
	        		opp.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
	        	} else {
					AUC_AuctionMaintenance.setOpportunityStageClosed(opp);
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
			AUC_AuctionMaintenance.UpdateNPSPPayments(new List<Opportunity> { opp }, strPaymentMethod, strCheckNumber);        	
			
			// if creating a new contact role, then also put the contact on the Tickets campaign.
			if (contactRole.Id == null) {
				AUC_AuctionMaintenance.saveOppContactRole(contactRole);
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
			List<CampaignMember> listCmpMbrCreate = new List<CampaignMember>();
			List<CampaignMember> listCmpMbrUpdate = new List<CampaignMember>();
			Set<Id> setContactIdCreate = new Set<Id>();
			
			for (CampaignMember cmpmbr : listCmpMbrAttendees) {
				if (cmpmbr.Id != null) {
					listCmpMbrUpdate.add(cmpmbr);					
				} else if (cmpmbr.ContactId != null) {
					cmpmbr.CampaignId = auctionMaintenance.campaignIdAuctionAttendees;
					if (cmpmbr.Bid_Number__c == null) cmpmbr.Bid_Number__c = null;	// force it so updates won't use previous value.
					cmpmbr.Auction_Ticket_OppId__c = opp.Id;
					listCmpMbrCreate.add(cmpmbr);
					setContactIdCreate.add(cmpmbr.ContactId);
				}
			}
			
			update listCmpMbrUpdate;

			// before inserting new CM's, make sure the contacts weren't already on the Attendees campaign.
			// if they were, go ahead and delete their previous CM, and save their new CM.
			List<CampaignMember> listCmpMbrDelete = new List<CampaignMember>();
			listCmpMbrDelete = [SELECT Id FROM CampaignMember WHERE CampaignId = :auctionMaintenance.campaignIdAuctionAttendees
				AND ContactId IN :setContactIdCreate];
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
	        if (opp.Id == null) {
		        strSaveResults = 'Error encountered while trying to save auction ticket purchase and attendees.  ';
	        } else {
		        strSaveResults = 'The ticket purchase has been saved, but errors were encountered trying to save the attendees.  ';
	        }
            ApexPages.addMessages(e);            

			// assume they already charged the card, and we don't want the page refresh to reload the payment terminal.
			fShowPanelCreditCard = false;
            return null;
        }              
	}

	public PageReference Cancel() {
		PageReference p;
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if (retURL == null || retURL == '') {
			p = Page.AuctionTickets;
		} else {
			p = new PageReference(retURL);
		}
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
	public Boolean fShowPanelCreditCard { get; set; }
	
	// public method to show the credit card panel
	public PageReference ShowPanelCreditCard() {
		fShowPanelCreditCard = true;
		strPaymentMethod = 'Credit Card';
		return null;
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
			//if (strCreditCardChargeURL == null && contactRole.contactId != null) {
			// always recompute, because we don't have callback when contactRole.contactId or opp.Amount changes.
			{ 
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
					listFormat.add(contactRole.ContactId);
					listFormat.add(auctionId);
					listFormat.add(String.valueOf(opp.Amount));
					listFormat.add(UserInfo.getSessionId());
					String strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
					listFormat.add(strServerURL);					
					listFormat.add(UserInfo.getOrganizationId());
					listFormat.add(opp.Id);
					str = String.format(str, listFormat);			
				}
				strCreditCardChargeURL = str;
			}
			return strCreditCardChargeURL;
		}
		private set;
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
	
	// property to tell whether there is no place to store the Payment Method 
	public Boolean isPaymentSettingsMissing {
		get {
			return AUC_AuctionConstants.isPaymentSettingsMissing;
		}
	}
}