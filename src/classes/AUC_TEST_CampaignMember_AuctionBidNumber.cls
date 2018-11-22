// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest 
private with sharing class AUC_TEST_CampaignMember_AuctionBidNumber {
	
	public static testMethod void TestCodeCoverage() {
	   		// create needed data
	    	Auction__c auction = new Auction__c (
				Name = 'Test Auction',
				Auction_Date__c = System.today()
			);  
			insert auction;  	
	    	
	    	Campaign campaign = [SELECT Id, Auction__c FROM Campaign
		        WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees
		        AND Auction__c = :auction.Id];
	    	System.assert(campaign.Id != null);
	    	System.assertEquals(auction.Id, campaign.Auction__c);
	    	
	    	Account accountT = new Account(Name='Test Account');
			insert accountT;
	    	   	   	
	    	Contact contact1 = new Contact(
	    		AccountId = accountT.Id,
	    		FirstName = 'Johnny1',
	    		LastName = 'Test'
	    	);
	    	insert contact1;
	    	
	    	CampaignMember campaignmember1 = new CampaignMember(
	    		CampaignId = campaign.Id,
	    		ContactId = contact1.Id,
	    		Bid_Number__c = 100,
	    		Status = 'Invited'
	    	);
	    	insert campaignmember1;
	    	System.assert(campaignmember1.Id != null);
	  				
	    	Contact contact2 = new Contact(
	    		AccountId = accountT.Id,
	    		FirstName = 'Johnny2',
	    		LastName = 'Test'
	    	);
	    	insert contact2;
	    	
	    	CampaignMember campaignmember2 = new CampaignMember(
	    		CampaignId = campaign.Id,
	    		ContactId = contact2.Id,
	    		Bid_Number__c = 200,
	    		Status = 'Invited'	    		
	    	);
	    	insert campaignmember2;
	    	System.assert(campaignmember2.Id != null);
	    	
	    	Contact contact3 = new Contact(
	    		AccountId = accountT.Id,
	    		FirstName = 'Johnny3',
	    		LastName = 'Test'
	    	);
	    	insert contact3;
	    	
	    	CampaignMember campaignmember3 = new CampaignMember( 
	    		CampaignId = campaign.Id,
	    		ContactId = contact3.Id,
	    		Bid_Number__c = null,
	    		Status = 'Invited'	    		
	    	);
	    	insert campaignmember3;	
	    	System.assert(campaignmember3.Id != null);
	    	    	
	    	Contact contact4 = new Contact(
	    		AccountId = accountT.Id,
	    		FirstName = 'Johnny4',
	    		LastName = 'Test'
	    	);
	    	insert contact4;
	    	
	    	CampaignMember campaignmember4 = new CampaignMember(
	    		CampaignId = campaign.Id,
	    		ContactId = contact4.Id,
	    		Bid_Number__c = 100,
	    		Status = 'Invited'	    		
	    	); 
			String error;
			try {
		    	insert campaignmember4;
		    	System.assert(false, 'Insert should have failed!');					
			} catch ( DmlException e ) {
				error = e.getMessage();
				System.debug (error);
			}			
			System.assert ( error != null && error.contains('Bid Number 100') );
			
			
			// now test bulk loading up to 20
			List<CampaignMember> listCM = new List<CampaignMember>();
			List<Contact> listC = new List<Contact>();
			for (Integer i = 0; i < 20; i++) {
		    	Contact contact = new Contact(
		    		AccountId = accountT.Id,
		    		FirstName = 'Johnny',
		    		LastName = 'Test' + i
		    	);
		    	listC.add(contact);
			}
			insert listC;					
									
			for (Integer i = 0; i < 20; i++) {
				CampaignMember cm = new CampaignMember(
					CampaignId = campaign.Id,
					ContactId = listC[i].Id,
					Bid_Number__c = i,
	    			Status = 'Invited'					
				);
				listCM.add(cm);
			}
			insert listCM;		 	
	    	    	
	}
}