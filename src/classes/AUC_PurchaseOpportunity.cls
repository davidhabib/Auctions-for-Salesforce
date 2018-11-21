// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

// a simple class to hold an opportunity, and some temporary variables for
// each row of the Auction Purchases grid, on the AuctionPurchases page.
// also used by AuctionCheckOut page.
public with sharing class AUC_PurchaseOpportunity {

	public AUC_PurchaseOpportunity() {
		opp = new Opportunity(RecordTypeId=AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem);
	}
    
	public AUC_PurchaseOpportunity(Opportunity oppExisting) {
		opp = oppExisting;
		// set initial state for IsPayNow
		if (opp != null) {
			IsPayNow = !opp.IsClosed;
		}
	}
    
    public Opportunity opp { get; set; }
    public Boolean IsPayNow { get; set; }
    public String contactId { get; set; } // could not use ID, or page's submit would fail since it would try to set these to ''
    public String strBidderNumberAndName { get; set; }
    public String strAuctionItemIDAndName { get; set; }
    public String strAmount { get; set; }  // to allow purchase page to bind to a string to detect null vs. $0.

    public Integer BidderNumber { 
    	get {
    		// return the bid number we extract from "bid number: contact name" formatted string
    		if (strBidderNumberAndName == null) return -1;
    		Integer i = strBidderNumberAndName.indexOf(': ');
    		if (i <= 0) return -1;
    		return Integer.valueOf(strBidderNumberAndName.substring(0, i));
    	}
    }
    
    public String strBidderName {
    	get {
    		// return the contact name we extract from "bid number: contact name" formatted string
    		if (strBidderNumberAndName == null) return null;
    		Integer i = strBidderNumberAndName.indexOf(': ');
    		if (i == -1) return strBidderNumberAndName;
    		return strBidderNumberAndName.substring(i+2);
    	}
    }

    public String strAuctionItemID { 
    	get {
    		// return the bid number we extract from "AuctionItemID: auction item name" formatted string
    		if (strAuctionItemIDAndName == null) return null;
    		Integer i = strAuctionItemIDAndName.indexOf(': ');
    		if (i == -1) return null;
    		return strAuctionItemIDAndName.substring(0, i);
    	}
    }
    
    public String strAuctionItemName {
    	get {
    		// return the auction item name we extract from "AuctionItemID: auction item name" formatted string
    		if (strAuctionItemIDAndName == null) return null;
    		Integer i = strAuctionItemIDAndName.indexOf(': ');
    		if (i == -1) return strAuctionItemIDAndName;
    		return strAuctionItemIDAndName.substring(i+2);
    	}
    }
}