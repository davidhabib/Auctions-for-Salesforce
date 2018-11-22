// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
private with sharing class AUC_TEST_Auction_ProtectCampaigns {
	
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
    	
		try {
			delete campaign;
			System.assert(false);
		} catch (Exception ex) {
			System.assert(ex.getMessage().contains('You must delete the Auction first'));
		}
	}
}