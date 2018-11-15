// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionAutoBidNumber_TEST {

	static testMethod void CodeCoverageTests() {

		// temporarily set household custom setting to hit more code coverage
		delete [SELECT Id FROM AuctionSettings__c];
		AuctionSettings__c settings = new AuctionSettings__c();
		settings.Contact_Household_Field__c = 'AccountId';
		settings.Contact_Household_Name_Field__c = 'Account.Name';
		settings.Allow_Duplicate_Bid_Numbers__c = false;
		settings.Name = 'test settings';
		insert settings;
		System.assertEquals('AccountId', AUC_AuctionConstants.strContactHouseholdField);

		// create needed data
		Account acc = new Account(Name='My Test Account for Contacts');
		insert acc;

		Integer cContact = 10;
		List<Contact> listContact = new List<Contact>();
		for (Integer i = 0; i < cContact; i++) {
			listContact.add(new Contact(FirstName='Person:' + i, LastName='Test', AccountId=acc.Id));
		}
		insert listContact;

		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;
		Id campaignId = am.campaignIdAuctionAttendees;

		List<CampaignMember> listCM = new List<CampaignMember>();
		for (Integer i = 0; i < cContact; i++) {
			listCM.add(new CampaignMember(CampaignId = campaignId, ContactId = listContact[i].Id));
		}
		insert listCM;

		// now test our  page
		PageReference p = new PageReference('Page.AuctionAutoBidNumbers');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);

		//instantiate the controller for this opp
		AUC_CTRL_AuctionAutoBidNumbers ctrl = new AUC_CTRL_AuctionAutoBidNumbers();
		System.assert(ctrl.listCMBidNumbers != null);
		ctrl.fOneBidNumberPerHousehold = true;
		ctrl.AutoBidNumbersSet();
		System.assertEquals('Successfully set the Bid Number for ' + cContact + ' auction attendees.', ctrl.strAutoBidNumberResult);

		// test duplicate detection failure handling
		ctrl.listCMBidNumbers[0].iNewBidNumber = 123;
		ctrl.listCMBidNumbers[2].iNewBidNumber = 123;
		ctrl.AutoBidNumbersSet();
		System.assert(ctrl.strAutoBidNumberResult.contains('Errors occurred'));

		// also test no param scenario.
		p = new PageReference('Page.AuctionAutoBidNumbers');
		Test.setCurrentPageReference(p);
		ctrl = new AUC_CTRL_AuctionAutoBidNumbers();
		System.assertEquals('There was no AuctionId passed as a parameter to the page.', ctrl.strAutoBidNumberResult);
		ctrl.AutoBidNumbersSet();
		System.assertEquals('The specified Auction was invalid or did not have an Auction Attendees Campaign.  No bid numbers were changed.', ctrl.strAutoBidNumberResult);

		System.assert(ctrl.Cancel() != null);
	}

}