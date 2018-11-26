// Written by DavId Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckIn {

	public class CheckInException extends Exception {}

	// constructor for the class 
	public AUC_CTRL_AuctionCheckIn() {

		// force IE into Standards Mode
		ApexPages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		 		
		// get the current auction we were invoked FROM, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a String to avoId getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
		
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

	// private status String for reporting the results of saving.
    @TestVisible private String strSaveResults { get; set; }

	// status String for reporting helpful instructions and the results of saving.
	public String strStatus {
		
		get {
			Boolean fAttendee = contactIdAttendee != null && contactIdAttendee != '';
			Boolean fCaptain = IdCaptain != null && IdCaptain != '';
			Boolean fSearchAttendee = searchAttendee != null && searchAttendee != '';
			
			if (strSaveResults != null) {
				strStatus = strSaveResults;
			} else if (!fAttendee && !fCaptain && !fSearchAttendee) {
				strStatus = 'Enter the name of a guest to display their information.'; 
			} else if (!fAttendee && fSearchAttendee) {
				strStatus = 'There is no contact in the database with that name.  Enter a new contact in the New Contact section.';
			} else if (fAttendee && !fCaptain) {
				strStatus = 'Please enter a table captain.  Tables hosted by organizations are at the end of the list.';
			} else if (!fAttendee && fCaptain) {
				strStatus = 'Select one of the guests from the Guest list below or enter a new contact to add to this Table Captain.';
			} else if (fAttendee && fCaptain) {
				strStatus = 'Update the guest\'s information and click <b>Save & Check In Contact</b>.<br/>Save their credit card by clicking <b>Save Credit Card</b>.' +
					'<br/>If the guest needs to buy tickets, click on the <b>Add Ticket Purchase</b> checkbox.' + 
					'<br/><br/>It is <b>recommended</b> that only one person per household provIde credit card information and have a bId number.';
			}
			return strStatus;
		}
		private set;
	}

	@TestVisible private AUC_AuctionMaintenance auctionMaintenance;
		
	// the currently selected Auction
	public Id auctionId { get; set; } 
		
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions { get; set; }

	// callback when the user changes the current auction in the dropdown.
	public PageReference ChangeAuction() {
		// clear any previous save message
		strSaveResults = null;
		
		// clear out all state that is specific to the auction
		auctionMaintenance.auctionId = auctionId;

		// setting contactId's to null will null out their dependencies.
		contactIdAttendee = null;
		IdCaptain = null;
		return null;
	}  

	// holds the currently selected Attendee contact
	// has to be a String to allow a null Id ('') to get returned from the page.
	public String contactIdAttendee { 
		get; 
		set {
			// first invalidate anything dependent on a change
			if (contactIdAttendee != value) {
				strNameAttendee = null;
				attendeeEdit = null;
				oppTicketAttendee = null;
				strCreditCardValidateURL = null;
				fShowPanelCreditCard = false;
			}
			contactIdAttendee = value;
			if (contactIdAttendee == '') {
				contactIdAttendee = null;
			}
		}		
	}
	
	// holds the currently selected Attendee's name	
	public String strNameAttendee { 
		get {
			if (strNameAttendee == null && contactIdAttendee != null) {
				Contact con = [SELECT Name FROM Contact WHERE Id = :contactIdAttendee];
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
		Id Id = IdCaptainForContactIdAttendee(contactIdAttendee);
		if (Id != null) IdCaptain = Id;
		return null;
	}  
	
	// this parameter is used in scenarios WHERE the page
	// needs us to search for an attendee before it could wait
	// for the return from its javascript remoting call to get data
	public String searchAttendee { get; set; }

	// callback when the user changes the Attendee contact lookup and submits too quick.
	public PageReference SearchAttendeeLookup() {
		if (searchAttendee != null && searchAttendee != '') {
			List<Contact> listCon = [SELECT Id FROM Contact WHERE Name = :searchAttendee];
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
	@TestVisible private Id IdCaptainForContactIdAttendee(Id IdAttendee) {

		// get the CampaignMember for the attendee
		List<CampaignMember> listCM = [SELECT ContactId, Auction_Ticket_OppId__c, Table_Captain__c FROM CampaignMember 
			WHERE ContactId = :IdAttendee AND CampaignId = :auctionMaintenance.campaignIdAuctionAttendees ];
		if (listCM.size() > 0) {
			if (listCM[0].Table_Captain__c != null) {
				// if they have a table captain, use it
				return listCM[0].Table_Captain__c;
			} else {
				// otherwise return the ticket purchaser
				List<OpportunityContactRole> listOCR = [SELECT ContactId FROM OpportunityContactRole 
						WHERE IsPrimary=TRUE AND OpportunityId = :listCM[0].Auction_Ticket_OppId__c];
				if (listOCR.size() > 0) {
					return listOCR[0].ContactId;
				} else {
					// if we dIdn't find a OCR, it might be just an ticket bought by an Account.
					List<Opportunity> listOpp = [SELECT AccountId FROM Opportunity WHERE Id = :listCM[0].Auction_Ticket_OppId__c];
					if (listOpp.size() > 0) {
						return listOpp[0].AccountId;
					}
				}
			}
		}
		return null;
	}
	
	// holds the currently selected Captain.  
	// Note that this can be either a Contact Id or an Account Id
	// has to be a String to allow a null Id ('') to get returned from the page.
	public String IdCaptain { 
		get; 
		set {
			// invalidate anything dependent on a change
			if (IdCaptain != value) {
				strNameCaptain = null;
				listAttendees = null;
				listOppCaptain = null;
				cmCaptain = null;
				mapTicketOppIdAttendeesLeft = null;
			}
			IdCaptain = value;			
			if (IdCaptain == '') IdCaptain = null;
				
			// set the current attendee's captain and table if their CM has is new.  
			if (attendeeEdit != null && attendeeEdit.cm != null && attendeeEdit.cm.Id == null) { 
            	attendeeEdit.cm.Table_Captain__c = (IsCaptainContact ? IdCaptain : null);	            	
	            if (cmCaptain != null) {
	            	attendeeEdit.cm.Table_Name_Number__c = cmCaptain.Table_Name_Number__c;
	            }
	            // see if there is an available ticket for this guest
	            // and use its PaId status.
	            attendeeEdit.cm.Paid__c = PaIdTicketAvailable();
			}										 
		}
	}
	
	// private utility to check if the current Captain has a free ticket available
	// and whether it has been paId for.
	@TestVisible private Boolean PaidTicketAvailable() {
        Integer iLast = listAttendees.size() - 1;
        if (iLast >= 0 && listAttendees[iLast].cm.ContactId == null) {
        	return listAttendees[iLast].cm.Paid__c;
        } else {
        	return false;
        }		
	}
	
	// differentiates whether our table captain is a Contact or an Account
	public Boolean IsCaptainContact {
		get {
			if (IdCaptain == null || 
				AUC_AuctionConstants.getObjectTypeFromId(IdCaptain) == Contact.SObjectType) {
				return true;
			} else {
				return false;
			}
		}
	}
	
	// holds the currently selected Captain's name	
	public String strNameCaptain { 
		get {
			if (strNameCaptain == null && IdCaptain != null) {
				if (IsCaptainContact) {				
					Contact con = [SELECT Name FROM Contact WHERE Id = :IdCaptain];
					strNameCaptain = con.Name;
				} else {
					Account acc = [SELECT Name FROM Account WHERE Id = :IdCaptain];
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
		// the setter for IdCaptain will
		// invalidate anything dependent.
		return null;
	}  
	
	// the ticket opportunity(ies) for the currently selected Captain
	@TestVisible private List<Opportunity> listOppCaptain {
		get {
			if (listOppCaptain == null) {
				listOppCaptain = new List<Opportunity>();
				
				if (auctionId == null) return listOppCaptain;
					
				// if we have a table captain, look for their ticket first.
				if (IdCaptain != null) {
					if (IsCaptainContact) {
					 	listOppCaptain = [SELECT Id, AccountId, CampaignId, Number_of_Tickets__c, Amount, StageName, IsWon
							FROM Opportunity 
							WHERE RecordTypeId = :AUC_AuctionMaintenance.recordtypeIdAuctionTicket
								AND CampaignId = :auctionMaintenance.campaignIdAuctionTickets
								AND Id IN (SELECT OpportunityId FROM OpportunityContactRole WHERE ContactId = :IdCaptain)];
					} else {
						listOppCaptain = [SELECT Id, AccountId, CampaignId, Number_of_Tickets__c, Amount, StageName
							FROM Opportunity
							WHERE RecordTypeId = :AUC_AuctionMaintenance.recordtypeIdAuctionTicket
								AND CampaignId = :auctionMaintenance.campaignIdAuctionTickets
								AND AccountId  = :IdCaptain];
					}
					if (listOppCaptain.size() > 0) {
						return listOppCaptain;
					}					
				}
				// if there is no ticket holder, create a new ticket opp.
				listOppCaptain.add(new Opportunity(
					RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
					CampaignId = auctionMaintenance.campaignIdAuctionTickets));
			} 
			return listOppCaptain;
		}
		private set;			 
	}  
	
	// the campaign member for the currently selected Captain
	@TestVisible private CampaignMember cmCaptain {
		get {
			if (cmCaptain == null && IdCaptain != null) {
				// look for it in the attendees list.
				for (Attendee att : listAttendees) {
					if (att.cm != null && att.cm.ContactId == IdCaptain) {
						cmCaptain = att.cm;
						return cmCaptain;
					}
				}	
			}
			return cmCaptain;
		}
		set;
	}
	
	// flag to track whether to add a ticket purchase for the Attendee
	public Boolean fAddTicketPurchase { get; set; }
	
	// the optional ticket opportunity for the current Attendee
	public Opportunity oppTicketAttendee {
		get {
			if (oppTicketAttendee == null) {
				
				// see if they already have a ticket opp.
				if (contactIdAttendee != null) {
					String rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
					String cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;
					
					String strSoql = 'SELECT Id';
					for (String str : AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'GW_Auctions__AuctionCheckInFS')) {
						strSoql += ', Opportunity.' + str;
					}
					strSoql += ' FROM OpportunityContactRole ' +
					' WHERE IsPrimary=true AND contactId = :contactIdAttendee AND ' +
						' opportunity.RecordTypeId = :rtTicket AND opportunity.campaignId = :cmpIdTickets';			
				
					List<OpportunityContactRole> listOCR = Database.query(strSoql);
					if (listOCR.size() > 0) {
						oppTicketAttendee = listOCR[0].Opportunity;
					}
				}
				
				// if lookup failed, create a new opp.
				if (oppTicketAttendee == null) {
					oppTicketAttendee = new Opportunity(
						RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
						CampaignId = auctionMaintenance.campaignIdAuctionTickets,
						CloseDate = System.today()
					);
				}
			}
			return oppTicketAttendee;
		}
		private set;
	}

	// a map to track number of slots left for each ticket
	@TestVisible private Map<Id, Double> mapTicketOppIdAttendeesLeft { get; set; }
		
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public List<Attendee> listAttendees {
    	get {
    		if (listAttendees == null) {
    			listAttendees = new List<Attendee>(); 
    			mapTicketOppIdAttendeesLeft = new Map<Id, Double>();			
    			
    			// find any existing attendees on the captain's ticket(s)
    			if (listOppCaptain.size() > 0) { 
    				Set<Id> setTicketOppId = new Set<Id>();
					Double numTickets = 0;
    				for (Opportunity opp : listOppCaptain) {
    					if (opp.Id != null) {
	    					setTicketOppId.add(opp.Id);
				    		numTickets += opp.Number_of_Tickets__c == null ? 0 : opp.Number_of_Tickets__c;
				    		mapTicketOppIdAttendeesLeft.put(opp.Id, opp.Number_of_Tickets__c);
    					}			    				    		
    				}
    				
	    			// load up their CM info.
	    			String strSoql = 'SELECT ' + strCMFields +
    					' FROM CampaignMember' + 
    					' WHERE campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' AND ' +
    						' (GW_Auctions__Auction_Ticket_OppId__c IN :setTicketOppId ';
    				if (IsCaptainContact && IdCaptain != null) {
    					strSoql += ' OR GW_Auctions__Table_Captain__c = :IdCaptain ';
    				}
    				strSoql += ')';
    				
    				List<CampaignMember> listCM = Database.query(strSoql);
    					
    				// create a map so we can match CM's with Contacts
    				Map<Id, CampaignMember> mapContactIdCM = new Map<Id, CampaignMember>();
    				for (CampaignMember cm : listCM) {
    					mapContactIdCM.put(cm.ContactId, cm);
    				}    			

	    			// load up their contact info.
	    			Set<Id> setKeys = mapContactIdCM.keySet();
	    			List<Contact> listCon = Database.query('SELECT ' + strContactFields + 
	    				' FROM Contact WHERE Id IN :setKeys' + 
	    				' ORDER BY Name');    			
    			
	    			for (Contact con : listCon) {
	    				listAttendees.add(new Attendee(mapContactIdCM.get(con.Id), con));
	    			}
	    			    					
					// add slots for people who specified this table captain, but aren't on the captain's ticket opp
					for (CampaignMember cm : listCM) {
						if (!setTicketOppId.contains(cm.GW_Auctions__Auction_Ticket_OppId__c)) {
							numTickets++;
						} else {
							Double cLeft = mapTicketOppIdAttendeesLeft.get(cm.GW_Auctions__Auction_Ticket_OppId__c);
							mapTicketOppIdAttendeesLeft.put(cm.GW_Auctions__Auction_Ticket_OppId__c, cLeft - 1);
						}
					}
					
					// create new CampaignMembers for any additional attendees on this ticket  					
		    		CampaignMember cmCaptain = mapContactIdCM.get(IdCaptain);
		            for (Integer i = listCon.size()+1; i <= numTickets; i++) {
		                CampaignMember cm = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);		                
	                	cm.Table_Captain__c = (IsCaptainContact ? IdCaptain : null);
	                	cm.Paid__c = (listOppCaptain[0].Amount != null);
	                	if (cmCaptain != null) {
	                		cm.Table_Name_Number__c = cmCaptain.Table_Name_Number__c;
	                	}	                	
	                	Contact con = new Contact();
	    				listAttendees.add(new Attendee(cm, con));
		            }
		        }
    		}
	        return listAttendees;
    	}

    	private set;    	
    } 	

	// helper routine to return all Contact field names from the Field Set
	@TestVisible private String strContactFields {
		get {
			if (strContactFields == null) {
				strContactFields = AUC_AuctionMaintenance.strFieldNamesFromFieldSet('Contact', 'GW_Auctions__AuctionsCheckInFS');
				
				// make sure Name field that is used in Guests datatable is included.
				if (!strContactFields.contains(' Name,')) strContactFields += ', Name';
			}
			return strContactFields;
		}
		set;
	}
	
	// helper routine to return all CampaignMember field names from the Field Set
	// we could optimize this to use fieldset api, but the CM fields are used
	// in two places that may require different fields.  so its easiest to just load them all.
	@TestVisible private String strCMFields {
		get {
			if (strCMFields == null) {
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.CampaignMember.fields.getMap();
				List<String> listStrFields = new List<String>();
				listStrFields.addAll(mapS.keySet());  
				strCMFields = '';
				for (String str : listStrFields) {
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
	                CampaignMember cm = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                	cm.Table_Captain__c = (IsCaptainContact ? IdCaptain : null);
                	cm.ContactId = contactIdAttendee;
                	cm.Paid__c = PaidTicketAvailable();
                	if (cmCaptain != null) {
                		cm.Table_Name_Number__c = cmCaptain.Table_Name_Number__c;
                	}
                	

					if (contactIdAttendee != null) {
						con = Database.query('SELECT ' + strContactFields + ' FROM Contact WHERE Id = :contactIdAttendee');

		                // we still need to make sure they don't already have a CM.  only happens in a case WHERE the CM
		                // is no longer attached to either a Ticket Opp or a Table Captain.
		    			String strSoql = 'SELECT ' + strCMFields +
	    					' FROM CampaignMember' + 
	    					' WHERE campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' AND ' +
	    						' contactId = :contactIdAttendee';
	    				List<CampaignMember> listCM = Database.query(strSoql);
	    				if (listCM.size() > 0) {
	    					cm = listCM[0];
	    					if (cm.Table_Captain__c == null) {
	    						// go ahead and prefill the current table captain.
			                	cm.Table_Captain__c = (IsCaptainContact ? IdCaptain : null);
	    					}
	    				}
					}
                	attendeeEdit = new Attendee(cm, con);
				}
			}
			return attendeeEdit; 
		}
		private set;
	}

	// find the Attendee for the given contactId.
	@TestVisible private Attendee attendeeFromId(Id cId) {
		if (cId == null) {
			return null;
		}
		for (Attendee att : listAttendees) {
			if (att.con.Id == cId) {
				return att;
			}
		}
		return null;
	}

	// utility to ensure the attendee campaign has a status of 'Checked In'
	// needed to support pre 3.15 Auctions.
	@TestVisible private void AllowCheckedInStatus() {
		Id cmpId = auctionMaintenance.campaignIdAuctionAttendees;
		if (cmpId != null) {
			List<CampaignMemberStatus> listCMS = [SELECT Id FROM CampaignMemberStatus WHERE Label = 'Checked In' AND CampaignId = :cmpId];
			// if not found, let's add it.
			CampaignMemberStatus cms;
			if (listCMS.size() == 0) {
			    cms = new CampaignMemberStatus(
			        Label = 'Checked In',
			        CampaignId = cmpId,
			        HasResponded = true,
			        SortOrder = 500
			    );
			    insert(cms);   						
			}
		}
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
      		// don't update contactIdAttendee, or it will clear attendeeEdit (and its CM)
      		
      		
      		// 2. create/update optional Ticket
      		if (fAddTicketPurchase) {

				// add validation for required fields, since we couldn't do it on the page
				validateTicketOpp(oppTicketAttendee);

	        	if (oppTicketAttendee.Id == null) {

		        	// create the opp for the ticket purchase        	
					oppTicketAttendee.Name = auctionMaintenance.StrOppTicketName(null, attendeeEdit.con.Id);					   
					oppTicketAttendee.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auctionId) *
						oppTicketAttendee.Number_of_Tickets__c;
		        	
		            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
					// if so, we need to set the Opp's Account to make the rollups work.
					if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
						Contact contact = [SELECT Name, AccountId FROM Contact WHERE Id=:attendeeEdit.con.Id];	
						oppTicketAttendee.AccountId = contact.AccountId;
					}
					        	
					AUC_AuctionMaintenance.didUpdateOppWithNPSPOCRData(oppTicketAttendee, attendeeEdit.con.Id);
	        		insert oppTicketAttendee;
					
					// only create contact role if client's code dIdn't do it!
					OpportunityContactRole ocr = new OpportunityContactRole();
					ocr.OpportunityId = oppTicketAttendee.Id;
					ocr.ContactId = attendeeEdit.con.Id;
					ocr.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
					ocr.IsPrimary = true;
					AUC_AuctionMaintenance.saveOppContactRole(ocr);
	        	} else {
	        		update oppTicketAttendee;
	        	}
      		}
      		
			// 3. create or update CampaignMember
			if (attendeeEdit.cm.Id == null) {
				attendeeEdit.cm.CampaignId = auctionMaintenance.campaignIdAuctionAttendees;
				attendeeEdit.cm.ContactId = attendeeEdit.con.Id;
			}
			AllowCheckedInStatus();
			attendeeEdit.cm.Status = 'Checked In';
			if (fAddTicketPurchase) {
				attendeeEdit.cm.Paid__c = true;
				attendeeEdit.cm.Auction_Ticket_OppId__c = oppTicketAttendee.Id; 
			} else if (attendeeEdit.cm.Auction_Ticket_OppId__c == null) {
				// find which captain's ticket has room for this attendee
				for (Opportunity opp : listOppCaptain) {
					if (mapTicketOppIdAttendeesLeft.get(opp.Id) > 0) {
						attendeeEdit.cm.Auction_Ticket_OppId__c = opp.Id;
						attendeeEdit.cm.Paid__c = (attendeeEdit.cm.Paid__c || opp.Amount != null);
						mapTicketOppIdAttendeesLeft = null; // so it will refresh
						break;
					}
				}								
			}
			if (attendeeEdit.cm.Id == null) {
				insert attendeeEdit.cm;				
			} else {
				update attendeeEdit.cm;
			}      					
			       	
        	strSaveResults = 'The Guest has been saved and checked in.';
        	
			// 4. save done, so clear our complete state
			listAttendees = null;	
			oppTicketAttendee = null;
			listOppCaptain = null;	
			fAddTicketPurchase = false;
			strNameAttendee = null;
			strNameCaptain = null;
			
			// when the page reloads, let's make sure we show the current attendee and (possibly new) captain.
			contactIdAttendee = attendeeEdit.con.Id;
			if (attendeeEdit.cm.Table_Captain__c != null) {
				IdCaptain = attendeeEdit.cm.Table_Captain__c;
			}
			return null;	
			        
        } catch (Exception e) {
           	strSaveResults = 'Error encountered while trying to save.';
            ApexPages.addMessages(e);
            return null;
        }               
	}

	// validate that required fields on the ticket are specified,
	// since we can't use the visualforce required tag, since the
	// section is not always visible.
	@TestVisible private void validateTicketOpp(Opportunity opp) {

		Schema.FieldSet fs = Schema.SObjectType.Opportunity.fieldSets.AuctionCheckInFS;
		for (Schema.FieldSetMember f : fs.getFields()) {
			if (opp.get(f.fieldPath) == null && (f.dbRequired || f.required)) {
				throw new CheckInException(f.label + ' must be specified on the new ticket purchase.');
			}
		}
	}

	// public method for the Next Guest button.  
	// clear out guest, keep captain, and refresh the page.
	public PageReference NextGuest() {
		contactIdAttendee = null;
		// force IE into Standards Mode
		ApexPages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		return null;
	}

	// public method for the Close button.  
	// use retURL if we have it, otherwise go to tickets tab.
	public PageReference Close() {
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if (retURL == null || retURL == '') {
			retURL = '/apex/GW_Auctions__AuctionTickets';
		}
		PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
	}

	// public property to get the commandButton URL
	// for the Authorize Credit Card button.	
	public String strCreditCardValidateURL {
		get {
			if (strCreditCardValidateURL == null) {
				String str = AUC_AuctionConstants.StrCreditCardValidateURLFormula();
				if (str != null) {
					// {0} = contactId
					// {1} = auctionId
					// {2} = amount		
					// {3} = sessionId
					// {4} = partner server url
					// {5} = organizationId
					List<String> listFormat = new List<String>();
					listFormat.add(contactIdAttendee);
					listFormat.add(auctionId);
					listFormat.add('0');
					listFormat.add(UserInfo.getSessionId());
					String strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
					listFormat.add(strServerURL);					
					listFormat.add(UserInfo.getOrganizationId());					
					str = String.format(str, listFormat);			
				}
				strCreditCardValidateURL = str;
			}
			return strCreditCardValidateURL;
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

	// public property on whether to display the credit card panel
	public Boolean fShowPanelCreditCard { get; set; }
	
	// public method to show the credit card panel
	public PageReference ShowPanelCreditCard() {
		fShowPanelCreditCard = true;
		return null;
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
	* Note that we've changed AuctionCheckIn to now use the version of this that looks at the Auction.
	* @param strFilter the subString to filter by 
	* @return List<Contact>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static List<Contact> getListContacts(String strFilter) {
    	strFilter = '%' + strFilter + '%';  
		List<Contact> listContacts = [SELECT Id, Name, MailingStreet, MailingCity 
        		FROM Contact WHERE 
				Name LIKE :strFilter
				ORDER BY Name ASC];
		return listContacts;
    } 		
	
	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts, optionally filtered by strFilter.
	* To try to avoId loading too many contacts, first search those on the Attendees list.  If none found,
	* then search all contacts.
	* @param auctionId the Auction to filter by 
	* @param strFilter the subString to filter by 
	* @return List<Contact>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static List<Contact> getListAttendees(String auctionId, String strFilter) {
    	strFilter = '%' + strFilter + '%';  
		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;

		// first look for contacts WHERE are on the Attendees campaign    	
        List<Contact> listContacts = [SELECT Id, Name, MailingStreet, MailingCity 
        		FROM Contact WHERE 
				Name LIKE :strFilter
					AND Id IN (SELECT ContactId FROM CampaignMember WHERE CampaignId = :auctionMaintenance.campaignIdAuctionAttendees)
				ORDER BY Name ASC];

		// if none found, then search all contacts
		if (listContacts.size() == 0) {
			listContacts = [SELECT Id, Name, MailingStreet, MailingCity 
        		FROM Contact WHERE 
				Name LIKE :strFilter
				ORDER BY Name ASC];
		}				
			
		return listContacts;
    } 		

	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Contacts and Accounts, who are ticket 
	* holders or table captains on the specified auction, optionally filtered by strFilter.
	* @param auctionId the Auction to filter by 
	* @param strFilter the subString to filter by 
	* @return List<SObject>, (Contacts and Accounts) which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static List<SObject> getListCaptains(String auctionId, String strFilter) {
    	strFilter = '%' + strFilter + '%';   	

		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;
		
		Set<Id> setContactId = new Set<Id>();
		Set<Id> setOppId = new Set<Id>();
		
		// get all the primary contacts for auction tickets
		for (List<OpportunityContactRole> listOCR : [SELECT ContactId, OpportunityId FROM OpportunityContactRole
			WHERE IsPrimary=TRUE AND
			(Opportunity.CampaignId=:auctionMaintenance.campaignIdAuctionTickets) AND
			Contact.Name LIKE :strFilter]) {
			
			// use set to avoId dups
			for (OpportunityContactRole ocr : listOCR) {
				setContactId.add(ocr.ContactId);
				setOppId.add(ocr.OpportunityId);
			}
		}
		
		// get all the table captains
		for (List<CampaignMember> listCM : [SELECT ContactId, Table_Captain__c FROM CampaignMember
			WHERE CampaignId = :auctionMaintenance.campaignIdAuctionAttendees AND
			Table_Captain__r.Name LIKE :strFilter]) {
			
			// use set to avoId dups
			for (CampaignMember cm : listCM) {
				setContactId.add(cm.Table_Captain__c);
			}
		}
		List<SObject> listContactCaptains = [SELECT Id, Name FROM Contact WHERE Id IN :setContactId ORDER BY Name];
		
		// now add any Accounts that own tickets.
		// since we don't really want to include 1:1 accounts when dealing with NPSP,
		// nor do we want accounts that were listed on the opp if there still was an indivIdual ticket purchaser,
		// we filter out opps that have primary contacts.
		Set<Id> setAccId = new Set<Id>();
		for (List<Opportunity> listOpp : [SELECT AccountId FROM Opportunity
			WHERE CampaignId=:auctionMaintenance.campaignIdAuctionTickets AND
			Account.Name LIKE :strFilter AND
			Id NOT IN :setOppId]) {
			
			// use set to avoId dups
			for (Opportunity opp : listOpp) {
				setAccId.add(opp.AccountId);
			}
		}
		List<SObject> listAccountCaptains = [SELECT Id, Name FROM Account WHERE Id IN :setAccId ORDER BY Name];

		// add our list of contacts and accounts together
		List<SObject> listSobj = new List<SObject>();
		listSobj.addAll(listContactCaptains);
		listSobj.addAll(listAccountCaptains);	
		return listSobj; 
    }
}