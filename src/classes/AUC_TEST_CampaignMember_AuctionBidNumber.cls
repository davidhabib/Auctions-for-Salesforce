// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest 
private with sharing class AUC_TEST_CampaignMember_AuctionBidNumber {
	
	public static testMethod void TestCodeCoverage() {
	   		// create needed data
	    	Auction__c auction = new Auction__c (
				Name = 'Test Auction',
				Auction_Date__c = System.Today()
			);  
			insert auction;  	
	    	
	    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees and Auction__c = :auction.id];
	    	System.assert(campaign.Id != null);
	    	System.assertEquals(auction.id, campaign.Auction__c);
	    	
	    	Account accountT = new Account(Name='Test Account');
			insert accountT;
	    	   	   	
	    	Contact contact1 = new Contact(
	    		AccountId = accountT.id,
	    		Firstname = 'Johnny1',
	    		Lastname = 'Test'
	    	);
	    	insert contact1;
	    	
	    	CampaignMember campaignmember1 = new CampaignMember(
	    		CampaignId = campaign.id,
	    		ContactId = contact1.id,
	    		Bid_Number__c = 100,
	    		Status = 'Invited'
	    	);
	    	insert campaignmember1;
	    	system.assert(campaignmember1.Id != null);
	  				
	    	Contact contact2 = new Contact(
	    		AccountId = accountT.id,
	    		Firstname = 'Johnny2',
	    		Lastname = 'Test'
	    	);
	    	insert contact2;
	    	
	    	CampaignMember campaignmember2 = new CampaignMember(
	    		CampaignId = campaign.id,
	    		ContactId = contact2.id,
	    		Bid_Number__c = 200,
	    		Status = 'Invited'	    		
	    	);
	    	insert campaignmember2;
	    	system.assert(campaignmember2.Id != null);
	    	
	    	Contact contact3 = new Contact(
	    		AccountId = accountT.id,
	    		Firstname = 'Johnny3',
	    		Lastname = 'Test'
	    	);
	    	insert contact3;
	    	
	    	CampaignMember campaignmember3 = new CampaignMember( 
	    		CampaignId = campaign.id,
	    		ContactId = contact3.id,
	    		Bid_Number__c = null,
	    		Status = 'Invited'	    		
	    	);
	    	insert campaignmember3;	
	    	system.assert(campaignmember3.Id != null);
	    	    	
	    	Contact contact4 = new Contact(
	    		AccountId = accountT.id,
	    		Firstname = 'Johnny4',
	    		Lastname = 'Test'
	    	);
	    	insert contact4;
	    	
	    	CampaignMember campaignmember4 = new CampaignMember(
	    		CampaignId = campaign.id,
	    		ContactId = contact4.id,
	    		Bid_Number__c = 100,
	    		Status = 'Invited'	    		
	    	); 
			string error;
			try {
		    	insert campaignmember4;
		    	system.assert(false, 'Insert should have failed!');					
			} catch ( DmlException e ) {
				error = e.getMessage();
				system.debug (error);
			}			
			System.Assert ( error != null && error.contains('Bid Number 100') );	   
			
			
			// now test bulk loading up to 20
			list<CampaignMember> listCM = new list<CampaignMember>();
			list<Contact> listC = new list<Contact>();
			for (integer i = 0; i < 20; i++) {
		    	Contact contact = new Contact(
		    		AccountId = accountT.id,
		    		Firstname = 'Johnny',
		    		Lastname = 'Test' + i
		    	);
		    	listC.add(contact);
			}
			insert listC;					
									
			for (integer i = 0; i < 20; i++) {										
				CampaignMember cm = new CampaignMember(
					CampaignId = campaign.id,
					ContactId = listC[i].id,
					Bid_Number__c = i,
	    			Status = 'Invited'					
				);
				listCM.add(cm);
			}
			insert listCM;		 	
	    	    	
	}
}