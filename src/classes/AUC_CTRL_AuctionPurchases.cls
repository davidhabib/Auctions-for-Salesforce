// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionPurchases extends PageControllerBase {

	// constructor
	public AUC_CTRL_AuctionPurchases() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'GW_Auctions__AuctionPurchasesTabFS');
       	strNameField = listStrFields[0]; 
       	strObjectType = 'Opportunity';			
	}
	
	public override string getStrPageUniqueName() {
		return 'Purchases';
	}
		
	public override string getStrSoql() {	
		string strSoql = 'select Id, ' + string.join(listStrFields, ',') + 
				' from opportunity ' +
        		'where (RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem  + '\'' + 
        		' or RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionGift  + '\') ' +
        		' and CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionAttendees + '\'';
		
		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' and Name like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        		
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		PageReference p = new PageReference('/apex/GW_Auctions__AuctionNewPurchaseWizard?auctionId=' + ctrlSoqlListView.auctionId);
		return p;		
	}

	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	
    	Auction_Item__c ai = new Auction_Item__c (
    		Auction_Item_Name__c = 'Test Auction Item',
    		Auction__c = auction.id,
    		FMV_Override__c = 100
    	);
    	insert ai;
    	    	
		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;
		System.assertEquals(campaign.Id, am.campaignIdAuctionAttendees);

    	Opportunity oppPurchase= new Opportunity (
    		Name = 'My Auction Item Purchase',
    		CampaignId = campaign.id,
    		RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
    		StageName = 'Won Not Thanked',
    		CloseDate = System.Today(),
    		Amount = 150
    	);
    	insert oppPurchase;
    			
		//point to our VF page
		PageReference p = new PageReference('Page.AuctionPurchases');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller 
		AUC_CTRL_AuctionPurchases pageCtrl = new AUC_CTRL_AuctionPurchases();
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		compCtrl.pageController = pageCtrl;
		system.assert(pageCtrl.listStrFields != null);
		system.assert(pageCtrl.strNameField != null);
		system.assert(pageCtrl.getStrSoql() != null);
		system.assert(pageCtrl.NewItem() != null);
		
	}


}