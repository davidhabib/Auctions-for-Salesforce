// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckIn { 

	// constructor for the class 
	public AUC_CTRL_AuctionCheckIn() {

		// force IE into Standards Mode
		Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		 		
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
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
				strStatus = 'Enter the name of a guest to display their information.'; 
			} else if (!fAttendee && fSearchAttendee) {
				strStatus = 'There is no contact in the database with that name.  Enter a new contact in the New Contact section.';
			} else if (fAttendee && !fCaptain) {
				strStatus = null;
				strStatus = 'Please enter a table captain.  Tables hosted by organizations are at the end of the list.';
			} else if (!fAttendee && fCaptain) {
				strStatus = 'Select one of the guests from the Guest list below or enter a new contact to add to this Table Captain.';
			} else if (fAttendee && fCaptain) {
				strStatus = null;
				strStatus = 'Update the guest\'s information and click <b>Save & Check In Contact</b>.<br/>Save their credit card by clicking <b>Save Credit Card</b>.' + 
					'<br/>If the guest needs to buy tickets, click on the <b>Add Ticket Purchase</b> checkbox.' + 
					'<br/><br/>It is <b>recommended</b> that only one person per household provide credit card information and have a bid number.';
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
				fShowPanelCreditCard = false;
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
				listAttendees = null;
				listOppCaptain = null;
				cmCaptain = null;
				mapTicketOppIdAttendeesLeft = null;
			}
			idCaptain = value;			
			if (idCaptain == '') idCaptain = null;
				
			// set the current attendee's captain and table if their CM has is new.  
			if (attendeeEdit != null && attendeeEdit.cm != null && attendeeEdit.cm.Id == null) { 
            	attendeeEdit.cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);	            	
	            if (cmCaptain != null) {
	            	attendeeEdit.cm.Table_Name_Number__c = cmCaptain.Table_Name_Number__c;
	            }
	            // see if there is an available ticket for this guest
	            // and use its Paid status.
	            attendeeEdit.cm.Paid__c = PaidTicketAvailable();
			}										 
		}
	}
	
	// private utility to check if the current Captain has a free ticket available
	// and whether it has been paid for.
	private boolean PaidTicketAvailable() {	
        integer iLast = listAttendees.size() - 1;
        if (iLast >= 0 && listAttendees[iLast].cm.contactId == null) {
        	return listAttendees[iLast].cm.Paid__c;
        } else {
        	return false;
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
	
	// the ticket opportunity(ies) for the currently selected Captain
	private list<Opportunity> listOppCaptain { 
		get {
			if (listOppCaptain == null) {
				listOppCaptain = new list<Opportunity>();
				
				if (auctionId == null) return listOppCaptain;
					
				// if we have a table captain, look for their ticket first.
				if (idCaptain != null) {
					if (IsCaptainContact) {
					 	listOppCaptain = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount, StageName, IsWon 
							from Opportunity 
							where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
								and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
								and Id in (select OpportunityId from OpportunityContactRole where contactId = :idCaptain)];
					} else {
						listOppCaptain = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount, StageName
							from Opportunity
							where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
								and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
								and AccountId  = :idCaptain];
					}
					if (listOppCaptain.size() > 0) {
						return listOppCaptain;
					}					
				}
				// if there is no ticket holder, create a new ticket opp.
				listOppCaptain.add(new Opportunity(
					RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
					CampaignId = auctionMaintenance.campaignIdAuctionTickets));
			} 
			return listOppCaptain;
		}
		private set;			 
	}  
	
	// the campaign member for the currently selected Captain
	private CampaignMember cmCaptain { 
		get {
			if (cmCaptain == null && idCaptain != null) {
				// look for it in the attendees list.
				for (Attendee att : listAttendees) {
					if (att.cm != null && att.cm.contactId == idCaptain) {
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
	public boolean fAddTicketPurchase { get; set; }
	
	// the optional ticket opportunity for the current Attendee
	public Opportunity oppTicketAttendee {
		get {
			if (oppTicketAttendee == null) {
				
				// see if they already have a ticket opp.
				if (contactIdAttendee != null) {
					string rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
					string cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;
					
					string strSoql = 'select Id';
					for (string str : AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'GW_Auctions__AuctionCheckInFS')) {
						strSoql += ', Opportunity.' + str;
					}
					strSoql += ' from OpportunityContactRole ' +
					' where IsPrimary=true and contactId = :contactIdAttendee and ' +
						' opportunity.RecordTypeId = :rtTicket and opportunity.campaignId = :cmpIdTickets';			
				
					list<OpportunityContactRole> listOCR = database.query(strSoql);
					if (listOCR.size() > 0) {
						oppTicketAttendee = listOCR[0].Opportunity;
					}
				}
				
				// if lookup failed, create a new opp.
				if (oppTicketAttendee == null) {
					oppTicketAttendee = new Opportunity(
						RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
						CampaignId = auctionMaintenance.campaignIdAuctionTickets,
						CloseDate = system.Today()
					);
				}
			}
			return oppTicketAttendee;
		}
		private set;
	}

	// a map to track number of slots left for each ticket
	private map<ID, double> mapTicketOppIdAttendeesLeft { get; set; } 
		
	// the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public list<Attendee> listAttendees {
    	get {
    		if (listAttendees == null) {
    			listAttendees = new list<Attendee>(); 
    			mapTicketOppIdAttendeesLeft = new map<ID, double>();			
    			
    			// find any existing attendees on the captain's ticket(s)
    			if (listOppCaptain.size() > 0) { 
    				set<ID> setTicketOppId = new set<ID>();
					double numTickets = 0;
    				for (Opportunity opp : listOppCaptain) {
    					if (opp.Id != null) {
	    					setTicketOppId.add(opp.Id);
				    		numTickets += opp.Number_Of_Tickets__c == null ? 0 : opp.Number_Of_Tickets__c;	
				    		mapTicketOppIdAttendeesLeft.put(opp.Id, opp.Number_Of_Tickets__c);
    					}			    				    		
    				}
    				
	    			// load up their CM info.
	    			string strSoql = 'select ' + strCMFields +
    					' from CampaignMember' + 
    					' where campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' and ' +
    						' (GW_Auctions__Auction_Ticket_OppId__c in :setTicketOppId ';
    				if (IsCaptainContact && idCaptain != null) {
    					strSoql += ' or GW_Auctions__Table_Captain__c = :idCaptain ';
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
	    			    					
					// add slots for people who specified this table captain, but aren't on the captain's ticket opp
					for (CampaignMember cm : listCM) {
						if (!setTicketOppId.contains(cm.GW_Auctions__Auction_Ticket_OppId__c)) {
							numTickets++;
						} else {
							double cLeft = mapTicketOppIdAttendeesLeft.get(cm.GW_Auctions__Auction_Ticket_OppId__c);
							mapTicketOppIdAttendeesLeft.put(cm.GW_Auctions__Auction_Ticket_OppId__c, cLeft - 1);
						}
					}
					
					// create new CampaignMembers for any additional attendees on this ticket  					
		    		CampaignMember cmCaptain = mapContactIdCM.get(idCaptain);
		            for (integer i = listCon.size()+1; i <= numTickets; i++) {
		                CampaignMember cm = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);		                
	                	cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
	                	cm.Paid__c = (listOppCaptain[0].amount != null);
	                	if (cmCaptain != null) {
	                		cm.table_name_number__c = cmCaptain.Table_Name_Number__c;
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
	private string strContactFields {
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
	private string strCMFields {
		get {
			if (strCMFields == null) {
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
	                CampaignMember cm = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                	cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
                	cm.contactId = contactIdAttendee;
                	cm.Paid__c = PaidTicketAvailable();
                	if (cmCaptain != null) {
                		cm.table_name_number__c = cmCaptain.Table_Name_Number__c;
                	}
                	

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
	    					cm = listCM[0];
	    					if (cm.Table_Captain__c == null) {
	    						// go ahead and prefill the current table captain.
			                	cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
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
	private Attendee attendeeFromId(ID cId) {
		if (cId == null) return null;
		for (Attendee att : listAttendees) {
			if (att.con.Id == cId) {
				return att;
			}
		}
		return null;
	}

	// utility to ensure the attendee campaign has a status of 'Checked In'
	// needed to support pre 3.15 Auctions.
	private	void AllowCheckedInStatus() {
		ID cmpId = auctionMaintenance.campaignIdAuctionAttendees;
		if (cmpId != null) {
			list<CampaignMemberStatus> listCMS = [Select Id From CampaignMemberStatus WHERE Label = 'Checked In' and CampaignId = :cmpId];
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

	        	if (oppTicketAttendee.Id == null) {

		        	// create the opp for the ticket purchase        	
					oppTicketAttendee.Name = auctionMaintenance.StrOppTicketName(null, attendeeEdit.con.Id);					   
					oppTicketAttendee.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(AuctionId) * 
						oppTicketAttendee.Number_Of_Tickets__c;      	
		        	
		            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
					// if so, we need to set the Opp's Account to make the rollups work.
					if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
						Contact contact = [select Name, AccountId from Contact where Id=:attendeeEdit.con.Id];	
						oppTicketAttendee.AccountId = contact.AccountId;
					}
					        	
					AUC_AuctionMaintenance.didUpdateOppWithNPSPOCRData(oppTicketAttendee, attendeeEdit.con.Id);
	        		insert oppTicketAttendee;
					
					// only create contact role if client's code didn't do it!
					if (AUC_AuctionConstants.fCreateOppContactRoles(oppTicketAttendee.Id, attendeeEdit.con.Id)) {				
		        		OpportunityContactRole ocr = new OpportunityContactRole();
						ocr.OpportunityId = oppTicketAttendee.Id;
						ocr.contactId = attendeeEdit.con.Id;
			        	ocr.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
						ocr.IsPrimary = true;
						insert ocr;
					}
	        	} else {
	        		update oppTicketAttendee;
	        	}
      		}
      		
			// 3. create or update CampaignMember
			if (attendeeEdit.cm.Id == null) {
				attendeeEdit.cm.campaignId = auctionMaintenance.campaignIdAuctionAttendees;
				attendeeEdit.cm.contactId = attendeeEdit.con.Id;
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
			if (attendeeEdit.cm.id == null) {
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
				idCaptain = attendeeEdit.cm.Table_Captain__c;
			}
			return null;	
			        
        } catch (Exception e) {
           	strSaveResults = 'Error encountered while trying to save.  ';
            ApexPages.addMessages(e);            
            return null;
        }               
	}

	// public method for the Next Guest button.  
	// clear out guest, keep captain, and refresh the page.
	public PageReference NextGuest() {
		contactIdAttendee = null;
		// force IE into Standards Mode
		Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
		return null;
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
					// {0} = contactId
					// {1} = auctionId
					// {2} = amount		
					// {3} = sessionId
					// {4} = partner server url
					// {5} = organizationId
					list<string> listFormat = new list<string>();
					listFormat.add(contactIdAttendee);
					listFormat.add(auctionId);
					listFormat.add('0');
					listFormat.add(UserInfo.getSessionId());
					string strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
					listFormat.add(strServerURL);					
					listFormat.add(UserInfo.getOrganizationId());					
					str = string.format(str, listFormat);			
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

	// public property on whether to display the credit card panel
	public boolean fShowPanelCreditCard { get; set; }
	
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
	* @description Javascript Remoting method to return a list of Contacts, optionally filtered by strFilter.
	* To try to avoid loading too many contacts, first search those on the Attendees list.  If none found,
	* then search all contacts.
	* @param auctionId the Auction to filter by 
	* @param strFilter the substring to filter by 
	* @return list<Contact>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static list<Contact> getListAttendees(string auctionId, string strFilter) {
    	strFilter = '%' + strFilter + '%';  
		if (auctionId == null || auctionId == '') return null;
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;

		// first look for contacts where are on the Attendees campaign    	
        list<Contact> listContacts = [select Id, Name, MailingStreet, MailingCity 
        		from Contact where 
				Name like :strFilter 
					and Id in (select contactId from CampaignMember where campaignId = :auctionMaintenance.campaignIdAuctionAttendees)
				order by Name asc];

		// if none found, then search all contacts
		if (listContacts.size() == 0) {
			listContacts = [select Id, Name, MailingStreet, MailingCity 
        		from Contact where 
				Name like :strFilter 
				order by Name asc];	
		}				
			
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
		system.assert(ctrl.listSOAuctions.size() > 0);
		system.assertEquals(0, ctrl.listAttendees.size());
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
		
		// verify the ticket opp and ocr
		list<Opportunity> listOpp = [select Id, Name, Amount from Opportunity];
		system.assertEquals(1, listOpp.size());
		list<OpportunityContactRole> listOCR = [select Id, ContactId from OpportunityContactRole where isPrimary=true];
		system.assertEquals(1,listOCR.size());
		system.assertEquals(contact.Id, listOCR[0].ContactId);
		
		// verify the campaignmember
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
    	Account acc2 = new Account(Name='Another Test Account');
    	insert acc2;    	
		Opportunity opp = new Opportunity(				
			RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
			CampaignId = ctrl.auctionMaintenance.campaignIdAuctionTickets
		);				
		opp.AccountId = acc2.Id;
		opp.Amount = 1000;
		opp.StageName = 'Won Closed';
		opp.Number_Of_Tickets__c = 10;
		opp.Name = 'my test account ticket purchase';
		opp.CloseDate = system.today();
		insert opp;
		ctrl.idCaptain = acc2.Id;
		ctrl.ChangeCaptainLookup();
		system.assertEquals('Another Test Account', ctrl.strNameCaptain);
		system.assertEquals(false, ctrl.IsCaptainContact);
		system.assertEquals(acc2.Id, ctrl.idCaptain);
		system.assert(ctrl.listOppCaptain != null);
		system.assertEquals(ctrl.listOppCaptain[0].Id, opp.Id);
		system.debug(ctrl.listAttendees);
		system.assertEquals(10, ctrl.listAttendees.size());
		
		// save another contact to the account table
		ctrl.contactIdAttendee = null;
		ctrl.ChangeAttendeeLookup();
		ctrl.idCaptain = acc2.Id;
		ctrl.ChangeCaptainLookup();
		ctrl.attendeeEdit.con.FirstName = 'Joey';
		ctrl.attendeeEdit.con.LastName = 'Test';
		system.assertEquals(null, ctrl.strSaveResults);
		ctrl.SaveAttendeeInfo();
		system.assert(ctrl.strSaveResults != null);
		system.assertEquals(opp.Id, ctrl.attendeeEdit.cm.Auction_Ticket_OppId__c);
		system.assert(ctrl.contactIdAttendee != null);	
		system.assertEquals(acc2.Id, ctrl.idCaptainForcontactIdAttendee(ctrl.contactIdAttendee));

		// test remoting functions
		system.assert(AUC_CTRL_AuctionCheckIn.getListContacts('Test').size() >= 3);		
		system.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Johnny Test').size() >= 1);
		system.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Another Test Account').size() >= 1);
					
				
	}		

}