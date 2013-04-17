// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionItems extends PageControllerBase {

	// constructor
	public AUC_CTRL_AuctionItems() {
		strFields = new list<string>{'Name', 'GW_Auctions__Fair_Market_Value__c', 
			'GW_Auctions__Category__c', 'GW_Auctions__Auction_Group__c' };				        	
       	strNameField = 'GW_Auctions__Auction_Item_Name__c'; 	
       	strObjectType = 'GW_Auctions__Auction_Item__c';			
	}

	public override string getStrPageUniqueName() {
		return 'AuctionItems';
	}	
	
	public override string getStrSoql() {	
		string strSoql = 'select Id, GW_Auctions__Auction_Item_Name__c, Name, GW_Auctions__Fair_Market_Value__c, GW_Auctions__Auction_Group__c, ' +
				'Category__c, GW_Auctions__Auction__c from GW_Auctions__Auction_Item__c ' +
				'where GW_Auctions__Auction__c=\'' + ctrlSoqlListView.auctionId + '\''; 

		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' and GW_Auctions__Auction_Item_Name__c like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        		
				
		//strSoql += ' order by GW_Auctions__Auction_Item_Name__c';        		
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		// ideally, we'd pass the AuctionId to the new page, but I haven't 
		// figured out how to do that in a way that works with a managed package.
		string strPrefix = Schema.getGlobalDescribe().get('Auction_Item__c').getDescribe().getKeyPrefix();
		//string strAuctionFldId = 'CF00NA0000001MnD3';  NOTE: couldn't find a way to get this at runtime!
		//list<Auction__c> listAuc = [select Id, Name from Auction__c where Id = :ctrlSoqlListView.auctionId] ;

		PageReference p = new PageReference('/' + strPrefix + '/e?' + 
			// strAuctionFldId + '=' + (listAuc.size() > 0 ? listAuc[0].Name : '') + '&' + 
			// strAuctionFldId + '_lkid=' + ctrlSoqlListView.auctionId + 
			'&retURL=/apex/GW_Auctions__AuctionItems');
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

		Auction_Item__c ai = new Auction_Item__c(
			Auction__c = auction.Id,
			Auction_Item_Name__c = 'Test Auction Item'
		);  
		insert ai;
		  	  	
		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.auctionId = auction.Id;
		
		//point to our VF page
		PageReference p = new PageReference('Page.AuctionItems');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller 
		AUC_CTRL_AuctionItems pageCtrl = new AUC_CTRL_AuctionItems();
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		compCtrl.pageController = pageCtrl;
		system.assert(pageCtrl.strFields != null);
		system.assert(pageCtrl.strNameField != null);
		system.assert(pageCtrl.getStrSoql() != null);
		system.assert(pageCtrl.NewItem() != null);
				
	}


}