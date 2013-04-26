// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_CampaignMember_AuctionBidNumber on CampaignMember (before insert, before update) {
	
	// allow user to disable this trigger
	if (AUC_AuctionConstants.fAllowDuplicateBidNumbers) 
		return;

	// While this version was efficient in using only 1 soql, it could run into 
	// governor limits if the total number of Bid Numbers in the database was over 1000.
	//
	// get the list of all current CampaignMembers 
	// List<CampaignMember> listCm = [select CampaignId, Bid_Number__c from CampaignMember where Bid_Number__c <> null];
	
	// so we must reduce the list by looking at the CampaignId's and BidNumber's we care about
	// NOTE: Bid_Number is a Double, but we always cast it to an Integer, to avoid issues when comparing, eg., 1000 vs 1000.0
	Set<Id> setCampaignId = new Set<Id>();
	Set<Integer> setBidNumber = new Set<Integer>();
	for (CampaignMember cm : trigger.new) {
		//system.debug('Trying to insert/update BidNumber: ' + string.valueof(cm.Bid_Number__c) + ' CampaignId: ' + cm.CampaignId + ' ContactId: ' + cm.ContactId);
		if (cm.Bid_Number__c != null) {
			setCampaignId.add(cm.CampaignId);
			setBidNumber.add(cm.Bid_Number__c.intValue());
		}
	}
	
	// if no one is setting bid numbers, let's get out of here and be fast!
	if (setBidNumber.size() == 0) return;

	list<CampaignMember> listCm = [select Id, CampaignId, Bid_Number__c, ContactId  from CampaignMember 
		where CampaignId in :setCampaignId and Bid_Number__c in :setBidNumber];
			
	// create a map of their <CampaignId+BidNumbers,ContactId> for checking against. 
	Map<String, Set<Id>> mapCampaignIdBidNumberToId = new Map<String, Set<Id>>();
	for (CampaignMember cm : listCm) {
		String strKey = cm.CampaignId + String.valueOf(cm.Bid_Number__c.intValue());
		Set<Id> setId = mapCampaignIdBidNumberToId.get(strKey);
		if (setId == null) {
			setId = new Set<Id>();
			setId.add(cm.ContactId);
			mapCampaignIdBidNumberToId.put(strKey, setId);
			// system.debug('Create our map: just added strkey: ' + strKey + '  contactId: ' + cm.ContactId);			
		} else {
			setId.add(cm.ContactId);
		}				
	}
	
	// now make sure none of the new CM's use any of the existing bid numbers.	
	// note that we add the new bid numbers, to detect duplicates in the new set.	 
	for (CampaignMember cm : trigger.new) {
		if (cm.Bid_Number__c != null) {
			String strKey = cm.CampaignId + String.valueOf(cm.Bid_Number__c.intValue());
			Set<Id> setId = mapCampaignIdBidNumberToId.get(strKey);
			System.Assert(setId == null || setId.size() > 0);
			if (setId == null) {  // bid number not used, so now lets add it.
				setId = new Set<Id>();
				setId.add(cm.ContactId);
				mapCampaignIdBidNumberToId.put(strKey, setId);	
				// system.debug('Testing our map: just added strkey: ' + strKey + '  contactId: ' + cm.ContactId);			
			} else if (setId.size() > 1 || !setId.contains(cm.ContactId)) { // bid number is used, and not just by this item.
				cm.addError ('Bid Number ' + cm.Bid_Number__c + ' is already used.  It is recommended that only one member of a Household should be given a Bid Number.');
				// system.debug('Bid Number ' + cm.Bid_Number__c + ' is already used.');
			}
		}
	}
	

/***************
	// this version of the trigger avoids getting a list of all bid numbers, since that could be over the 1000 object limit
	// unfortunately, we are still limited by a maximum of 20 soql calls per trigger, so this will only work
	// if we restrict our trigger to batches <= 20.  DaveM and DaveH agreed that this was acceptable,
	// since from the UI, the user will never be entering large sets of bid numbers, and if they are trying to
	// do bulk data loading of bid numbers, than can just do them in batches <= 20.
	if (trigger.new.size() > 20)
		return;
	
	// a set to hold all the campaignId:BidNumber tuples we will be creating, to detect dups within our new list.
	Set<String> setCMNew = new Set<String>();
	
	for (CampaignMember cm : trigger.new) {
		if (cm.Bid_Number__c != null) {
			
			// make sure the bid number isn't already used by someone else
			list<CampaignMember> listCm = [select Id from CampaignMember 
				where CampaignId = :cm.CampaignId and Id <> :cm.Id and Bid_Number__c = :cm.Bid_Number__c limit 1];
			if (listCm.size() > 0) {	
				cm.addError ('Bid Number ' + cm.Bid_Number__c + ' is already used.');
				continue;
			} 

			// makes sure the bid number wasn't duplicated on the insert/update list.
			if (!setCMNew.add(cm.CampaignId + String.valueOf(cm.Bid_Number__c))) {
				cm.addError ('Bid Number ' + cm.Bid_Number__c + ' is already used.');
				continue;
			} 
				
		}
	}
		
***************/		
}