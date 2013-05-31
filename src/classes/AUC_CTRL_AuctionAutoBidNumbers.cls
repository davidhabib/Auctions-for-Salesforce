// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionAutoBidNumbers {
	
	// our batch size
	static integer cAttendeesInBatch = 1000;

	// constructor
	public AUC_CTRL_AuctionAutoBidNumbers() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));		
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionMaintenance.auctionId = strAuctionId;
			
			integer countCM = [select count() from CampaignMember where campaignId=:auctionMaintenance.campaignIdAuctionAttendees and Status<>'RSVP No'];
			if (countCM > cAttendeesInBatch) {
				strAutoBidNumberResult = 'Only displaying the first ' + cAttendeesInBatch + ' attendees, but Assign will update all ' + countCM + ' attendees.';
			}			
		} else {
			strAutoBidNumberResult = 'There was no AuctionId passed as a parameter to the page.';
		}	
		fOneBidNumberPerHousehold = true;	
		iStartingBidNumber = 100;	
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	
	public boolean fOneBidNumberPerHousehold { get; set; }
	
	public string strAutoBidNumberResult { get; set; }
	
	public integer iStartingBidNumber { get; set; }
	
	public boolean fHasHouseholds {
		get {
			return (AUC_AuctionConstants.strContactHouseholdField != null && 
				AUC_AuctionConstants.strContactHouseholdNameField != null);
		}
	}
	
	public list<CMBidNumber> listCMBidNumbers {
		get {
			if (listCMBidNumbers == null) {
				listCMBidNumbers = new list<CMBidNumber>();
				list<CampaignMember> listCM = database.query(strSoqlCMBatch(cAttendeesInBatch, 0));
				for (CampaignMember cm : listCM) {
					listCMBidNumbers.add(new CMBidNumber(cm));
				}
				RecalcBidNumbers();								
			}
			return listCMBidNumbers;
		}
		set; 		
	}
	
	// returns the soql string to load up the next batch of CampaignMembers
	private string strSoqlCMBatch(integer cLimit, integer iOffset) {
		ID campaignId = auctionMaintenance.campaignIdAuctionAttendees;
		string strSoql = 'select Id, Bid_Number__c, contact.LastName, contact.firstname';
		if (fHasHouseholds) {
			strSoql += ', contact.' + AUC_AuctionConstants.strContactHouseholdField;
			strSoql += ', contact.' + AUC_AuctionConstants.strContactHouseholdNameField;
		}
		strSoql += ' from CampaignMember ';
		strSoql += ' where campaignId=\'' + campaignId + '\' and contactId<>null and Status<>\'RSVP No\' ';
		strSoql += ' order by contact.LastName, contact.FirstName ';
		if (cLimit > 0) strSoql += ' limit ' + cLimit;
		if (iOffset > 0) strSoql += ' offset ' + iOffset;
		return strSoql;		
	}
	
	public PageReference RecalcBidNumbers() {
		strAutoBidNumberResult = null;
		
		integer iBid = iStartingBidNumber;
		set<ID> setHousehold = new set<ID>();
		for (CMBidNumber cmbn : listCMBidNumbers) {
			if (fOneBidNumberPerHousehold && fHasHouseholds) {
				Contact con = cmbn.cm.contact;
				ID idHH = (ID)con.get(AUC_AuctionConstants.strContactHouseholdField);
				if (idHH != null && !setHousehold.add(idHH)) {
					// household already seen, so don't give them a bid number.
					cmbn.iNewBidNumber = null;
					continue;
				}								
			}
			cmbn.iNewBidNumber = iBid++;
		}
		return null;		
	}
	
	public PageReference AutoBidNumbersSet() {
		Savepoint sp = Database.setSavepoint();
		try {
			ID campaignId = auctionMaintenance.campaignIdAuctionAttendees;
			if (campaignId != null) {				
				
				// first we have to clear all numbers, so we can safely assign numbers in batches.
				list<CampaignMember> listCMtoUpdate = new list<CampaignMember>();					
				for (list<CampaignMember> listCM : [select Id, Bid_Number__c from CampaignMember where campaignId=:campaignId]) {
						
					for (CampaignMember cm : listCM) {
						if (cm.Bid_Number__c != null) {
							cm.Bid_Number__c = null;
							listCMtoUpdate.add(cm);
						}
					}
					update listCMtoUpdate;
					listCMtoUpdate.clear();					
				}
				
				// copy over new bid numbers
				integer iBidNumberLast;
				for (CMBidNumber cmbn : listCMBidNumbers) {
					cmbn.iOldBidNumber = integer.valueOf(cmbn.cm.Bid_Number__c);
					cmbn.cm.Bid_Number__c = (cmbn.iNewBidNumber == 0 ? null : cmbn.iNewBidNumber);
					listCMtoUpdate.add(cmbn.cm);
					if (cmbn.iNewBidNumber != null && cmbn.iNewBidNumber <> 0) iBidNumberLast = cmbn.iNewBidNumber;
				}
				update listCMtoUpdate;
				
				// now deal with remaining batches
				integer cUpdated = AutoBidNumbersSetRemainingBatches(iBidNumberLast);

		        // force refresh of listCMBidNumbers
		        listCMBidNumbers = null;

				strAutoBidNumberResult = 'Successfully set the Bid Number for ' + (listCMtoUpdate.size() + cUpdated) + ' auction attendees.';
			} else {
				strAutoBidNumberResult = 'The specified Auction was invalid or did not have an Auction Attendees Campaign.  No bid numbers were changed.';
			}
        } catch (Exception e) {
        	// undo our intial delete of all bid numbers
        	Database.rollback(sp);
        	
        	// copy back bid numbers
			for (CMBidNumber cmbn : listCMBidNumbers) {
				cmbn.cm.Bid_Number__c = (cmbn.iOldBidNumber == 0 ? null : cmbn.iOldBidNumber);
				if (cmbn.iNewBidNumber == 0) cmbn.iNewBidNumber = null; 
			}
        	
			strAutoBidNumberResult = 'Errors occurred: ';
            ApexPages.addMessages(e);            
        }
        return null;
	}


	public integer AutoBidNumbersSetRemainingBatches(integer iBidNumberLast) {
		list<CampaignMember> listCMtoUpdate = new list<CampaignMember>();	
		set<ID> setHousehold = new set<ID>();		
		ID campaignId = auctionMaintenance.campaignIdAuctionAttendees;
		integer iOffset = cAttendeesInBatch;	
		integer cUpdated = 0;	
		
		// in batches assign the new numbers.	
		integer cCM = 0;							
		for (list<CampaignMember> listCM : database.query(strSoqlCMBatch(0, 0))) {
			
			for (CampaignMember cm : listCM) {
				
				// these were dealt with in our main code, but we still want to
				// cache their hhID's if needed.
				if (++cCM < cAttendeesInBatch) {
					if (fOneBidNumberPerHousehold && fHasHouseholds)  {
						Contact con = cm.contact;
						ID idHH = (ID)con.get(AUC_AuctionConstants.strContactHouseholdField);
						if (idHH != null) {
							setHousehold.add(idHH);
						}					
					}
					continue;					
				}
				
				// remaining batches we always update
				if (fOneBidNumberPerHousehold && fHasHouseholds)  {
					Contact con = cm.contact;
					ID idHH = (ID)con.get(AUC_AuctionConstants.strContactHouseholdField);
					if (idHH != null && !setHousehold.add(idHH)) {
						// household already seen, so don't give them a bid number.
						cm.Bid_Number__c = null;
					} else {
						cm.Bid_Number__c = ++ibidNumberLast;					
					}													
				} else {
					cm.Bid_Number__c = ++ibidNumberLast;
				}
				listCMtoUpdate.add(cm);
			}
			update listCMtoUpdate;
			cUpdated += listCMtoUpdate.size();
			listCMtoUpdate.clear();
		}	
		return (cUpdated);				
	}

	public PageReference Cancel() {
		PageReference p = new PageReference('/apex/AuctionTickets?auctionId='+auctionMaintenance.auctionId);
        p.setRedirect(true);
        return p;
	}
	
	// wrapper class to hold a CampaignMember and a new bid number
	public class CMBidNumber {
		
		public CampaignMember cm { get; set; }
		public integer iNewBidNumber { get; set; }
		public integer iOldBidNumber { get; set; }
		public string strHousehold { get; set; }
		
		public CMBidNumber(CampaignMember cmT) {
			cm = cmT;
			
			if (AUC_AuctionConstants.strContactHouseholdNameField != null) {
				list<string> listStr = AUC_AuctionConstants.strContactHouseholdNameField.split('\\.', 0);
				if (listStr.size() > 1) {
					Contact con = cm.contact;
					Sobject hh = con.getSobject(listStr[0]);
					if (hh != null) strHousehold = (string)hh.get(listStr[1]);
				}
			}
			
		}
	}
	
	//==================== TEST METHOD(s) ======================================
	@isTest(SeeAllData=true)		
	static  void CodeCoverageTests() {
		
		// temporarily set household custom setting to hit more code coverage
        delete [select id from AuctionSettings__c];		
		AuctionSettings__c settings = new AuctionSettings__c();
		settings.Contact_Household_Field__c = 'AccountId';
		settings.Contact_Household_Name_Field__c = 'Account.Name';
		settings.Allow_Duplicate_Bid_Numbers__c = false;
		settings.Name = 'test settings';
		insert settings;
		system.AssertEquals('AccountId', AUC_AuctionConstants.strContactHouseholdField);

    	// create needed data
    	Account acc = new Account(Name='My Test Account for Contacts');
    	insert acc;
    	
    	Integer cContact = 10;
    	list<Contact> listContact = new list<Contact>();
    	for (Integer i = 0; i < cContact; i++) {
    		listContact.add(new Contact(Firstname='Person:' + i, Lastname='Test', AccountId=acc.Id));
    	}
		insert listContact;
		    	
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
    	am.auctionId = auction.Id;
    	ID campaignId = am.campaignIdAuctionAttendees;
    	
    	list<CampaignMember> listCM = new list<CampaignMember>();
    	for (Integer i = 0; i < cContact; i++) {
    		listCM.add(new CampaignMember(campaignId = campaignId, contactId = listContact[i].Id));
    	}
		insert listCM;
		
		// now test our  page
		PageReference p = new PageReference('Page.AuctionAutoBidNumbers');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionAutoBidNumbers ctrl = new AUC_CTRL_AuctionAutoBidNumbers();
		System.Assert(ctrl.listCMBidNumbers != null);
		ctrl.fOneBidNumberPerHousehold = true;
		ctrl.AutoBidNumbersSet();		
		System.AssertEquals('Successfully set the Bid Number for ' + cContact + ' auction attendees.', ctrl.strAutoBidNumberResult);
		
		// test duplicate detection failure handling
		ctrl.listCMBidNumbers[0].iNewBidNumber = 123;
		ctrl.listCMBidNumbers[2].iNewBidNumber = 123;
		ctrl.AutoBidNumbersSet();	
		System.Assert(ctrl.strAutoBidNumberResult.contains('Errors occurred'));
				
		// also test no param scenario.
		p = new PageReference('Page.AuctionAutoBidNumbers');
		Test.setCurrentPageReference(p);
		ctrl = new AUC_CTRL_AuctionAutoBidNumbers();
		System.AssertEquals('There was no AuctionId passed as a parameter to the page.', ctrl.strAutoBidNumberResult);		
		ctrl.AutoBidNumbersSet();		
		System.AssertEquals('The specified Auction was invalid or did not have an Auction Attendees Campaign.  No bid numbers were changed.', ctrl.strAutoBidNumberResult);	
		
		System.Assert(ctrl.Cancel() != null);	
	}
}