// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionAutoBidNumbers {
	
	// our batch size
	static Integer cAttendeesInBatch = 1000;

	// constructor
	public AUC_CTRL_AuctionAutoBidNumbers() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));		
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionMaintenance.auctionId = strAuctionId;
			
			Integer countCM = [SELECT COUNT() FROM CampaignMember WHERE CampaignId=:auctionMaintenance.campaignIdAuctionAttendees AND Status<>'RSVP No'];
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
	
	public Boolean fOneBidNumberPerHousehold { get; set; }
	
	public String strAutoBidNumberResult { get; set; }
	
	public Integer iStartingBidNumber { get; set; }
	
	public Boolean fHasHouseholds {
		get {
			return (AUC_AuctionConstants.strContactHouseholdField != null && 
				AUC_AuctionConstants.strContactHouseholdNameField != null);
		}
	}
	
	public List<CMBidNumber> listCMBidNumbers {
		get {
			if (listCMBidNumbers == null) {
				listCMBidNumbers = new List<CMBidNumber>();
				List<CampaignMember> listCM = Database.query(strSoqlCMBatch(cAttendeesInBatch, 0));
				for (CampaignMember cm : listCM) {
					listCMBidNumbers.add(new CMBidNumber(cm));
				}
				RecalcBidNumbers();								
			}
			return listCMBidNumbers;
		}
		set; 		
	}
	
	// returns the soql String to load up the next batch of CampaignMembers
	private String strSoqlCMBatch(Integer cLimit, Integer iOffset) {
		Id campaignId = auctionMaintenance.campaignIdAuctionAttendees;
		String strSoql = 'SELECT Id, Bid_Number__c, Contact.LastName, Contact.firstname';
		if (fHasHouseholds) {
			strSoql += ', Contact.' + AUC_AuctionConstants.strContactHouseholdField;
			strSoql += ', Contact.' + AUC_AuctionConstants.strContactHouseholdNameField;
		}
		strSoql += ' FROM CampaignMember ';
		strSoql += ' WHERE CampaignId=\'' + campaignId + '\' AND ContactId<>NULL AND Status<>\'RSVP No\' ';
		strSoql += ' ORDER BY Contact.LastName, Contact.FirstName ';
		if (cLimit > 0) strSoql += ' LIMIT ' + cLimit;
		if (iOffset > 0) strSoql += ' OFFSET ' + iOffset;
		return strSoql;		
	}
	
	public PageReference RecalcBidNumbers() {
		strAutoBidNumberResult = null;
		
		Integer iBid = iStartingBidNumber;
		Set<Id> setHousehold = new Set<Id>();
		for (CMBidNumber cmbn : listCMBidNumbers) {
			if (fOneBidNumberPerHousehold && fHasHouseholds) {
				Contact con = cmbn.cm.Contact;
				Id idHH = (Id)con.get(AUC_AuctionConstants.strContactHouseholdField);
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
			UTIL_Describe.checkObjectUpdateAccess('CampaignMember');

			Id campaignId = auctionMaintenance.campaignIdAuctionAttendees;
			if (campaignId != null) {				
				
				// first we have to clear all numbers, so we can safely assign numbers in batches.
				List<CampaignMember> listCMtoUpdate = new List<CampaignMember>();					
				for (List<CampaignMember> listCM : [SELECT Id, Bid_Number__c FROM CampaignMember WHERE CampaignId=:campaignId]) {
						
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
				Integer iBidNumberLast;
				for (CMBidNumber cmbn : listCMBidNumbers) {
					cmbn.iOldBidNumber = Integer.valueOf(cmbn.cm.Bid_Number__c);
					cmbn.cm.Bid_Number__c = (cmbn.iNewBidNumber == 0 ? null : cmbn.iNewBidNumber);
					listCMtoUpdate.add(cmbn.cm);
					if (cmbn.iNewBidNumber != null && cmbn.iNewBidNumber <> 0) iBidNumberLast = cmbn.iNewBidNumber;
				}
				update listCMtoUpdate;
				
				// now deal with remaining batches
				Integer cUpdated = AutoBidNumbersSetRemainingBatches(iBidNumberLast);

		        // force refresh of listCMBidNumbers
		        listCMBidNumbers = null;

				strAutoBidNumberResult = 'Successfully set the Bid Number for ' + (listCMtoUpdate.size() + cUpdated) + ' auction attendees.';
			} else {
				strAutoBidNumberResult = 'The specified Auction was invalid or did not have an Auction Attendees Campaign.  No bid numbers were changed.';
			}
        } catch (Exception e) {
        	// undo our initial delete of all bid numbers
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


	public Integer AutoBidNumbersSetRemainingBatches(Integer iBidNumberLast) {
		List<CampaignMember> listCMtoUpdate = new List<CampaignMember>();	
		Set<Id> setHousehold = new Set<Id>();
		Integer cUpdated = 0;
		
		// in batches assign the new numbers.	
		Integer cCM = 0;							
		for (List<CampaignMember> listCM : Database.query(strSoqlCMBatch(0, 0))) {
			
			for (CampaignMember cm : listCM) {
				
				// these were dealt with in our main code, but we still want to
				// cache their hhID's if needed.
				if (++cCM < cAttendeesInBatch) {
					if (fOneBidNumberPerHousehold && fHasHouseholds)  {
						Contact con = cm.Contact;
						Id idHH = (Id)con.get(AUC_AuctionConstants.strContactHouseholdField);
						if (idHH != null) {
							setHousehold.add(idHH);
						}					
					}
					continue;					
				}
				
				// remaining batches we always update
				if (fOneBidNumberPerHousehold && fHasHouseholds)  {
					Contact con = cm.Contact;
					Id idHH = (Id)con.get(AUC_AuctionConstants.strContactHouseholdField);
					if (idHH != null && !setHousehold.add(idHH)) {
						// household already seen, so don't give them a bid number.
						cm.Bid_Number__c = null;
					} else {
						cm.Bid_Number__c = ++iBidNumberLast;
					}													
				} else {
					cm.Bid_Number__c = ++iBidNumberLast;
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
		public Integer iNewBidNumber { get; set; }
		public Integer iOldBidNumber { get; set; }
		public String strHousehold { get; set; }
		
		public CMBidNumber(CampaignMember cmT) {
			cm = cmT;
			
			if (AUC_AuctionConstants.strContactHouseholdNameField != null) {
				List<String> listStr = AUC_AuctionConstants.strContactHouseholdNameField.split('\\.', 0);
				if (listStr.size() > 1) {
					Contact con = cm.Contact;
					SObject hh = con.getSObject(listStr[0]);
					if (hh != null) strHousehold = (String)hh.get(listStr[1]);
				}
			}
			
		}
	}
}