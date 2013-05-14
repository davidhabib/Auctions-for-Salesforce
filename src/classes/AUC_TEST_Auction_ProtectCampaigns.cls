// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest 
private with sharing class AUC_TEST_Auction_ProtectCampaigns {
	
	public static testMethod void TestCodeCoverage() {
   		// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign 
    		where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees 
    			and Auction__c = :auction.id];
    	System.assert(campaign.Id != null);
    	System.assertEquals(auction.id, campaign.Auction__c);
    	
		try {
			delete campaign;
			system.assert(false);
		} catch (exception ex) {
			system.assert(ex.getMessage().contains('You must delete the Auction first'));
		}
	}
}