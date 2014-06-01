// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewItemPieceWizard {
	
	// public Properties	
	public Auction_Item_Piece__c aip { get; set; }			
	public Id oppDonatedItemId { get; set; } 
	public Id auctionItemId { get; set; }
	public Id auctionId { get; set; }
	

	private AUC_AuctionMaintenance auctionMaintenance;
	private ApexPages.StandardController stdController;
	private string strQueryParams;
	
	//constructor
	public AUC_CTRL_AuctionNewItemPieceWizard (ApexPages.StandardController controller) {
		
		//get record from standard controller
		stdController = controller;
        this.aip = (Auction_Item_Piece__c)controller.getRecord();
        
        // Keep track of any inbound query string parameters so they can be passed along when creating a new record  
        List<string> pageUrl = ApexPages.currentPage().getUrl().split('\\?');  
        if (pageUrl.size() > 1)
        	strQueryParams = pageUrl[1];          
        
        // we are getting called from either an Auction Item, or a Donated Item.
        // figure out which one, and then derive the auctionId.
        if (aip.Auction_Item__c != null) {
        	list<Auction_Item__c> listAI = [select Auction__c from Auction_Item__c where Id=:aip.Auction_Item__c];
        	auctionId = listAI[0].Auction__c;
        	auctionItemId = aip.Auction_Item__c;
        } 

        if (aip.Opportunity__c != null) {
        	list<Campaign> listCmp = [select Auction__c from Campaign where Id in 
        		(Select CampaignId from Opportunity where Id = :aip.Opportunity__c) ];
        	auctionId = listCmp[0].Auction__c;
	        oppDonatedItemId = aip.Opportunity__c;
	        // NOTE: we correctly set the oppId, but if there are no items left for this donation,
	        // it won't appear in the picklist of donated items, and thus it will come up empty.
        } 
        			
		auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;
	}
	
	// the list of opps to put in the Auction Donated Item dropdown
	public list<SelectOption> listSODonatedItems {
		get {
			list<SelectOption> listSO = new list<SelectOption>();
			listSO.add(new SelectOption('', ''));
			for (Opportunity opp : [select Auction_Donated_Item_Name__c, id, Number_Available__c, Number_of_Items__c, Amount  from Opportunity 
				where RecordTypeId=:AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem  
					and Number_Available__c > 0 
					and CampaignId=:auctionMaintenance.campaignIdAuctionDonors
				order by Auction_Donated_Item_Name__c desc]) {
					if (opp.Number_of_Items__c > 0) {
						Decimal cost = ((opp.Amount == null) ? 0 : opp.Amount) / opp.Number_of_Items__c;
						listSO.add(new SelectOption(opp.id, opp.Auction_Donated_Item_Name__c + ' (' + integer.valueOf(opp.Number_Available__c) + ' available at $' + String.valueOf(cost) + ' each)'  ));
					}
			}		
			return listSO;
		}
	}	
	
	// the list of Auction Items to put in the Auction Item dropdown
	public list<SelectOption> listSOAuctionItems {
		get {
			list<SelectOption> listSO = new list<SelectOption>();
			listSO.add(new SelectOption('', ''));
			for (Auction_Item__c ai : [select Id, Name, Auction_Item_Name__c from Auction_Item__c where Auction__c=:auctionId order by Name]) {
				listSO.add(new SelectOption(ai.id, ai.Name + ' - ' + ai.Auction_Item_Name__c));
			}		
			return listSO;
		}
	}	

	public PageReference Save() {
		aip.Auction_Item__c = auctionItemId;
		aip.Opportunity__c = oppDonatedItemId;
		return stdController.Save();
	}		
	
	public PageReference SaveAndNew() {
		if (Save() != null) {
			// there is no action method on the standard controller for New, so we must hack this.
			Apexpages.currentPage().setRedirect(true);
            return new PageReference('/' + aip.getSObjectType().getDescribe().getKeyPrefix() + '/e?' + strQueryParams);					
		}
		return null;
	}
	
	//==================== TEST METHOD(s) ======================================	
	static testmethod void TestCodeCoverage() {
	
	   	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	   	
    	Auction_Item__c auctionitem = new Auction_Item__c (
    		Auction_Item_Name__c = 'Test Auction item',
    		Auction__c = auction.id
    	);
    	insert auctionitem;
    	
		AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
    	Opportunity oppDonatedItem = new Opportunity (
    		Amount = 100,
    		Auction_Donated_Item_Name__c = 'Test Donated Item',
    		CampaignId = campaign.Id,
    		Name = 'Test Donated Item Opportunity',
    		Number_of_Items__c = 10,
    		RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem,
    		StageName = 'CLOSED WON',
    		CloseDate = System.Today()
    	);
    	insert oppDonatedItem;
    		
		//point to our VF page
		Test.setCurrentPage(new PageReference('Page.AuctionNewItemPieceWizard'));
		
		// create the AIP and set it up
		Auction_Item_Piece__c aip = new Auction_Item_Piece__c();
		aip.Auction_Item__c = auctionitem.Id;
		aip.Opportunity__c = oppDonatedItem.Id;

		//pass AIP into the controller
		ApexPages.StandardController sc = new ApexPages.standardController(aip);
		
		//pass the controller into the extension
		AUC_CTRL_AuctionNewItemPieceWizard ext = new AUC_CTRL_AuctionNewItemPieceWizard(sc);
		
		System.AssertEquals(auction.Id, ext.auctionId);
		System.AssertEquals(auctionitem.Id, ext.auctionItemId);
		System.AssertEquals(oppDonatedItem.Id, ext.oppDonatedItemId);
		System.AssertEquals(2, ext.listSOAuctionItems.size());	// 2 becuase of the empty entry
		System.AssertEquals(2, ext.listSODonatedItems.size());  // 2 becuase of the empty entry
		ext.aip.Quantity__c = 1;
		ext.aip.Actual_FMV__c = 10;
		ext.Save();
		 		
	}
}