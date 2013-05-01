// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

// a simple class to hold an opportunity, and some temporary variables for
// each row of the Auction Purchases grid, on the AuctionPurchases page.
// also used by AuctionCheckOut page.
public with sharing class AUC_PurchaseOpportunity {

	public AUC_PurchaseOpportunity() {
		opp = new Opportunity(recordtypeId=AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem);
	}
    
	public AUC_PurchaseOpportunity(Opportunity oppExisting) {
		opp = oppExisting;
		// set initial state for IsPayNow
		if (opp != null) {
			IsPayNow = !opp.IsClosed;
		}
	}
    
    public Opportunity opp { get; set; }
    public boolean IsPayNow { get; set; }
    public string contactId { get; set; } // could not use ID, or page's submit would fail since it would try to set these to ''
    public string strBidderNumberAndName { get; set; }
    public string strAuctionItemIDAndName { get; set; }
    public string strAmount { get; set; }  // to allow purchase page to bind to a string to detect null vs. $0.

    public integer BidderNumber { 
    	get {
    		// return the bid number we extract from "bid number: contact name" formatted string
    		if (strBidderNumberAndName == null) return -1;
    		integer i = strBidderNumberAndName.indexOf(': ');
    		if (i <= 0) return -1;
    		return integer.valueOf(strBidderNumberAndName.substring(0, i));
    	}
    }
    
    public string strBidderName {
    	get {
    		// return the contact name we extract from "bid number: contact name" formatted string
    		if (strBidderNumberAndName == null) return null;
    		integer i = strBidderNumberAndName.indexOf(': ');
    		if (i == -1) return strBidderNumberAndName;
    		return strBidderNumberAndName.substring(i+2);
    	}
    }

    public string strAuctionItemID { 
    	get {
    		// return the bid number we extract from "AuctionItemID: auction item name" formatted string
    		if (strAuctionItemIDAndName == null) return null;
    		integer i = strAuctionItemIDAndName.indexOf(': ');
    		if (i == -1) return null;
    		return strAuctionItemIDAndName.substring(0, i);
    	}
    }
    
    public string strAuctionItemName {
    	get {
    		// return the auction item name we extract from "AuctionItemID: auction item name" formatted string
    		if (strAuctionItemIDAndName == null) return null;
    		integer i = strAuctionItemIDAndName.indexOf(': ');
    		if (i == -1) return strAuctionItemIDAndName;
    		return strAuctionItemIDAndName.substring(i+2);
    	}
    }

	//==================== TEST METHOD(s) ======================================    
    static testMethod void TestCodeCoverage() {
    	AUC_PurchaseOpportunity apo = new AUC_PurchaseOpportunity();
    	System.Assert(apo.opp != null);
    	System.AssertEquals(-1, apo.BidderNumber);
    	System.AssertEquals(null, apo.strBidderName);
    	System.AssertEquals(null, apo.strAuctionItemID);
    	System.AssertEquals(null, apo.strAuctionItemName);
    	apo.strBidderNumberAndName = '123: Mr. Foo';
    	System.AssertEquals(123, apo.BidderNumber);
    	System.AssertEquals('Mr. Foo', apo.strBidderName);
    	apo.strAuctionItemIDAndName = '999: the auction item';
    	System.AssertEquals('999', apo.strAuctionItemID);
    	System.AssertEquals('the auction item', apo.strAuctionItemName);
    	apo.IsPayNow = false;
    	apo.contactId = null;
    }
    	
}