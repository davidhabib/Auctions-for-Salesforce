// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionAutoBidNumbers {

	// constructor
	public AUC_CTRL_AuctionAutoBidNumbers() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');		
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionMaintenance.auctionId = strAuctionId;
			
			integer countCM = [select count() from CampaignMember where campaignId=:auctionMaintenance.campaignIdAuctionAttendees and Status<>'RSVP No'];
			if (countCM > 900) {
				strAutoBidNumberResult = 'Only displaying first 900 attendees, but Assign will update all ' + countCM + ' attendees.';
			}			
		} else {
			strAutoBidNumberResult = 'There was no AuctionId passed as a parameter to the page.';
		}			
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	public String strAutoBidNumberResult { get; set; }
	public list<CampaignMember> listCMBidNumbers { 
		get {
			if (listCMBidNumbers == null) {
				ID campaignId = auctionMaintenance.campaignIdAuctionAttendees;
				listCMBidNumbers = [select Id, Bid_Number__c, contact.LastName, contact.firstname from CampaignMember where campaignId=:campaignId and Status<>'RSVP No' order by contact.LastName, contact.FirstName limit 900];
			}
			return listCMBidNumbers;
		}
		set; 
	}
	
	public PageReference AutoBidNumbersSet() {
		try {
			ID campaignId = auctionMaintenance.campaignIdAuctionAttendees;
			if (campaignId != null) {
				Integer ibid = 100;
				list<CampaignMember> listCMtoUpdate = new list<CampaignMember>();
				for (list<CampaignMember> listCM : [select Id, Bid_Number__c, contact.LastName, contact.firstname from CampaignMember where campaignId=:campaignId and Status<>'RSVP No' order by contact.LastName, contact.FirstName]) {
					for (CampaignMember cm : listCM) {
						if (cm.Bid_Number__c != null) {
							cm.Bid_Number__c = null;
							listCMtoUpdate.add(cm);
						}
					}
				}
				update listCMtoUpdate;
				listCMtoUpdate.clear();
					
				for (list<CampaignMember> listCM : [select Id, Bid_Number__c, contact.LastName, contact.firstname from CampaignMember where campaignId=:campaignId order by contact.LastName, contact.FirstName]) {
					for (CampaignMember cm : listCM) {
						cm.Bid_Number__c = ibid;
						ibid++;
						listCMtoUpdate.add(cm);
					}
				}					
				update listCMtoUpdate;
				listCMtoUpdate.clear();

				strAutoBidNumberResult = 'Successfully set the Bid Number for ' + (ibid-100) + ' auction attendees.';
			} else {
				strAutoBidNumberResult = 'The specified Auction was invalid or did not have an Auction Attendees Campaign.  No bid numbers were changed.';
			}
        } catch (Exception e) {
			strAutoBidNumberResult = 'Errors occurred: ';
            ApexPages.addMessages(e);            
        }
        // force refresh of listCMBidNumbers
        listCMBidNumbers = null;
        return null;
	}

	public PageReference Cancel() {
		PageReference p = new PageReference('/apex/AuctionTickets?auctionId='+auctionMaintenance.auctionId);
        p.setRedirect(true);
        return p;
	}
	
	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {

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
		ctrl.AutoBidNumbersSet();		
		System.AssertEquals('Successfully set the Bid Number for ' + cContact + ' auction attendees.', ctrl.strAutoBidNumberResult);
		
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