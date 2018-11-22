// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest 
private with sharing class AUC_TEST_AuctionDonatedItemOpp_RecalcFMV {
	
	public static testMethod void TestTrigger() {
	
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);  
		insert auction;  	
    	
    	// find donor campaign
    	Campaign campaign = [SELECT Id, Auction__c FROM Campaign WHERE Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors 
    		AND Auction__c = :auction.Id];
    	System.assertEquals(auction.Id, campaign.Auction__c);
    	
    	// create a donated item
    	Opportunity oppDonatedItem = new Opportunity (
    		Name = 'Test Opportunity',
    		Auction_Donated_Item_Name__c = 'Test Auction Donated item',
    		Amount = 100,
    		Number_of_Items__c = 1,
    		CampaignId = campaign.Id,
    		RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem,
    		StageName = 'Won Not Thanked',
    		CloseDate = System.today()
    	);
    	insert oppDonatedItem;

		// create an auction item
		Auction_Item__c ai = new Auction_Item__c (
			Name = 'AI1',
			Auction__c = auction.Id,
			Auction_Item_Name__c = 'my auction item'
		);
		insert ai;
		System.assert(ai.Id != null);
		
		// create the linkage between donated item and auction item
		Auction_Item_Piece__c aip = new Auction_Item_Piece__c(
			Auction_Item__c = ai.Id,
			Opportunity__c = oppDonatedItem.Id,
			Quantity__c = 1
		);				
		insert aip;
		System.assert(aip.Id != null);
		
		ai = [SELECT Id, Fair_Market_Value__c FROM Auction_Item__c WHERE Id = :ai.Id];
		System.assertEquals(100, ai.Fair_Market_Value__c);
		
		// now update the donated item's FMV and see if our AI gets updated
		oppDonatedItem.Number_of_Items__c = 10;
		update oppDonatedItem;
		ai = [SELECT Id, Fair_Market_Value__c FROM Auction_Item__c WHERE Id = :ai.Id];
		System.assertEquals(10, ai.Fair_Market_Value__c);
		
		oppDonatedItem.Amount = 200;
		update oppDonatedItem;
		ai = [SELECT Id, Fair_Market_Value__c FROM Auction_Item__c WHERE Id = :ai.Id];
		System.assertEquals(20, ai.Fair_Market_Value__c);
					
	}
}