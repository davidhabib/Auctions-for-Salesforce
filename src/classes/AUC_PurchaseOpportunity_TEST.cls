// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_PurchaseOpportunity_TEST {

	static testMethod void TestCodeCoverage() {
		AUC_PurchaseOpportunity apo = new AUC_PurchaseOpportunity();
		System.assert(apo.opp != null);
		System.assertEquals(-1, apo.BidderNumber);
		System.assertEquals(null, apo.strBidderName);
		System.assertEquals(null, apo.strAuctionItemID);
		System.assertEquals(null, apo.strAuctionItemName);
		System.assertEquals(null, apo.strAmount);
		apo.strBidderNumberAndName = '123: Mr. Foo';
		System.assertEquals(123, apo.BidderNumber);
		System.assertEquals('Mr. Foo', apo.strBidderName);
		apo.strAuctionItemIDAndName = '999: the auction item';
		System.assertEquals('999', apo.strAuctionItemID);
		System.assertEquals('the auction item', apo.strAuctionItemName);
		apo.IsPayNow = false;
		apo.contactId = null;

		Opportunity oppDonatedItem = new Opportunity (
			Name = 'Test Opportunity',
			Auction_Donated_Item_Name__c = 'Test Auction Ticket',
			Amount = 50,
			RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
			StageName = 'Won Not Thanked',
			CloseDate = System.today()
		);
		insert oppDonatedItem;
		AUC_PurchaseOpportunity apo2 = new AUC_PurchaseOpportunity(oppDonatedItem);
		System.assertEquals(oppDonatedItem, apo2.Opp);

	}
}