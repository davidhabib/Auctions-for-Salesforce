// Written by David Habib, copyright (c) 2009, 2010, 2011 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_SoqlListView extends ComponentControllerBase {

	// the set controller allows us to do paging in our pageTable
    public ApexPages.StandardSetController setCon {
    	get {
            if(setCon == null) {
            	string strSoql = pageController.getStrSoql();
            	
				// start out sorting on the main name field.
            	if (SortItemField == null) {
					SortItemField = pageController.strNameField;
					SortItemAsc = true;            		
            	}

            	if (SortItemField != null) {
            		strSoql += ' ORDER BY ' + SortItemField + (SortItemAsc ? ' ASC' : ' DESC');
            	}
            	// if there is no auction selected, return an empty result set.
            	if (auctionId == null) {
            		strSoql = 'select Id from opportunity where Id=null';
            	}
            	setCon = new ApexPages.StandardSetController(
            		Database.getQueryLocator(strSoql));
            }
            return setCon;
        } 
        set;
    }
          
    // how many pages in our current result set
    public integer NumberOfPages {
    	get {
    		if (setCon != null) {
    			NumberOfPages = (setCon.getResultSize() / setCon.getPageSize()) + 1;
    		}
    		return NumberOfPages;
    	}
    	set;
    }
    
    // how many records in our current result set
    public integer NumberOfItems {
    	get {
    		if (setCon != null) {
    			NumberOfItems = setCon.getResultSize();
    		}
    		return NumberOfItems;
    	}
    	set;
    }
	
	// constructor
	public AUC_CTRL_SoqlListView() {
		
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;	
		} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = listSOAuctions[1].getValue();
		}
		ChangeAuction();
		
	}
	
	// helper class we expose to our page controllers
	public AUC_AuctionMaintenance auctionMaintenance;
	
 	// the currently selected Auction
	public Id auctionId { get; set; }
	
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }

	// action method called when the selected Auction changes.	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		setCon = null;
		auctionMaintenance.auctionId = auctionId;
		strAlphaFilter = '%';
		return null;
	}

	// returns a list of sObject's for the current page view.
	public list<SObject> getlistPagedItem() {
   		return (list<SObject>) setCon.getRecords();
   	} 
	
	// holds the current letter we are filtering on 
	public string strAlphaFilter { get; set; }
	
	// force the page to refresh when the AlphaFilter changes
	public PageReference AlphaFilter() {
		setCon = null;
		return null;
	}
	
	// a hack to provide a list of the alphabet so the component
	// can iterate over the list to create links, rather than
	// explictly listing each link in the component.
	public list<string> listAlphaFilters {
		get {
			if (listAlphaFilters == null) {
				listAlphaFilters = new list<string>{'A','B','C','D','E','F','G','H',
						'I','J','K','L','M','N','O','P','Q','R',
						'S','T','U','V','W','X','Y','Z'};
			}
			return listAlphaFilters;
		}
		set;
	}
	
	// will hold the ID of the item to be deleted
	public ID idDeleteItem { get; set; }
	
	// action method to delete an item from the database.
	public PageReference DeleteItem() {
		if (idDeleteItem != null) {
			database.delete(idDeleteItem);
			idDeleteItem = null;
			setCon = null;
		}
		return null;	
	}

	// will hold the ID of the item to be edit
	public ID idEditItem { get; set; }
	
	// action method to edit an item.  defer to the page controller.
	public PageReference EditItem() {
		return pageController.EditItem(idEditItem);
	}
	
	// will hold the developer name of the field to be sorted
	public string SortItemField { get; set; }
	
	// whether current sorted ascending or descending.
	public boolean SortItemAsc { get; set; }
	
	// action method to sort a column.
	public PageReference SortItem() {
		SortItemAsc = SortItemAsc ? false : true;
		// force a requery
		setCon = null;		
		return null;
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

		
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		PageControllerBase pageCtrl = new AUC_CTRL_AuctionItems();
		compCtrl.pageController = pageCtrl;
		system.assertNotEquals(null, compCtrl.setCon); 
		system.assert(compCtrl.NumberOfPages >= 1);
		system.assert(compCtrl.NumberOfItems >= 1);
		system.assertEquals(auction.Id, compCtrl.listSOAuctions[1].getValue());
		system.assertEquals(null, compCtrl.ChangeAuction());
		system.assertNotEquals(null, compCtrl.getlistPagedItem());
		system.assertEquals('%', compCtrl.strAlphaFilter);
		system.assertNotEquals(null, compCtrl.listAlphaFilters);
		compCtrl.strAlphaFilter = 'A';
		compCtrl.AlphaFilter();
		system.assertEquals(0, compCtrl.NumberOfItems);
		compCtrl.strAlphaFilter = 'T';
		compCtrl.AlphaFilter();
		system.assertEquals(1, compCtrl.NumberOfItems);
		compCtrl.idEditItem = ai.Id;
		system.assertNotEquals(null, compCtrl.EditItem());
		compCtrl.idDeleteItem = ai.Id;
		system.assertEquals(null, compCtrl.DeleteItem());
		list<Auction_Item__c> listAI = [select Id from Auction_Item__c where Id = :ai.Id];
		system.assertEquals(0, listAI.size());
	}	
}