// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_AuctionDonatedItemOpp_RecalcFMV on Opportunity (after update) {
	
	// first find all the Donated Item Opps whose FMV has changed
	set<ID> setIdOpp = new set<ID>();
	for (Opportunity opp : trigger.new) {
		if (opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem) {
			Opportunity oppOld = trigger.oldMap.get(opp.Id);
			if ((opp.Amount != oppOld.Amount) || (opp.Number_of_Items__c != oppOld.Number_of_Items__c)) {
				setIdOpp.add(opp.Id);
			}
		}
	}

	// now find their related AIP's and update them
	list<Auction_Item_Piece__c> listAIP = [select Actual_FMV__c from Auction_Item_Piece__c where Opportunity__c in :setIdOpp];
	for (Auction_Item_Piece__c aip : listAIP) {
		aip.Actual_FMV__c = null;	// force it to get recalced.
	}
	update listAIP;
	
}