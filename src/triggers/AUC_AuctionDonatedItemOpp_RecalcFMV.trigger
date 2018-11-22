// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_AuctionDonatedItemOpp_RecalcFMV on Opportunity (after update) {
	
	// first find all the Donated Item Opps whose FMV has changed
	Set<Id> setIdOpp = new Set<Id>();
	for (Opportunity opp : Trigger.new) {
		if (opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem) {
			Opportunity oppOld = Trigger.oldMap.get(opp.Id);
			if ((opp.Amount != oppOld.Amount) || (opp.Number_of_Items__c != oppOld.Number_of_Items__c)) {
				setIdOpp.add(opp.Id);
			}
		}
	}

	// now find their related AIP's and update them
	List<Auction_Item_Piece__c> listAIP = [SELECT Actual_FMV__c FROM Auction_Item_Piece__c WHERE Opportunity__c IN :setIdOpp];
	for (Auction_Item_Piece__c aip : listAIP) {
		aip.Actual_FMV__c = null;	// force it to get recalced.
	}
	update listAIP;
	
}