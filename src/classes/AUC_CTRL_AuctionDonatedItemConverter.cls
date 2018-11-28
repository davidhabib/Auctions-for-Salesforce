// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionDonatedItemConverter {
	
	// constructor
	public AUC_CTRL_AuctionDonatedItemConverter() {
		auctionMaintenance = new AUC_AuctionMaintenance();
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));		
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionMaintenance.auctionId = strAuctionId;
			if (listNewAuctionItem.size() == 0) strConvertResult = 'There are no more available Donated Items that need an Auction Item.';			
		} else {
			strConvertResult = 'There was no AuctionId passed as a parameter to the page.';
		}
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	
	public String strConvertResult { get; set; }
	
	// wrapper class to hold an AuctionItem, Donated Item Opportunity, and a checkbox
	public class NewAuctionItem {	

		public Auction_Item__c ai { get; set; }
		public Opportunity donatedItem { get; set; }
		public Boolean isChecked { get; set; }
		public Integer quantity { get; set; }
		public Decimal FMV { get; set; }
		
		public NewAuctionItem(Auction_Item__c aiT, Opportunity donatedItemT) {
			ai = aiT;
			donatedItem = donatedItemT;
			isChecked = false;
			quantity = Integer.valueOf(donatedItemT.Number_Available__c);
			if (donatedItemT.Amount == null || donatedItemT.Number_of_Items__c == null || donatedItemT.Number_of_Items__c == 0) {
				FMV = 0;
			} else { 
				FMV = (donatedItemT.Amount / donatedItemT.Number_of_Items__c) * quantity;
			}
		}
	}
	
	// the list of new auction items that the visualforce page displays for editing
	public List<NewAuctionItem> listNewAuctionItem { 
		get {
			try {
				UTIL_Describe.checkObjectReadAccess('Opportunity');
				if (listNewAuctionItem == null) {
					listNewAuctionItem = new List<NewAuctionItem>();

					List<Opportunity> listOpp = [SELECT Id, Name, Amount, Number_of_Items__c, Number_Available__c,
						Auction_Donated_Item_Name__c, Description, Auction_Donated_Item_Restrictions__c FROM Opportunity
						WHERE CampaignId = :auctionMaintenance.campaignIdAuctionDonors AND
							RecordTypeId = :AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem AND
							Number_Available__c > 0
						ORDER BY Auction_Donated_Item_Name__c
						LIMIT :AUC_AuctionConstants.cDonatedItemConverterBatchSize];

					// cache set of already used auction item id's
					List<Auction_Item__c> listAI = [SELECT Name FROM Auction_Item__c WHERE Auction__c = :auctionMaintenance.auctionId];
					Set<String> setItemId = new Set<String>();
					for (Auction_Item__c ai : listAI) {
						setItemId.add(ai.Name);
					}
					Integer itemId = 100;

					for (Opportunity opp : listOpp) {
						Auction_Item__c ai = new Auction_Item__c();
						ai.Auction__c = auctionMaintenance.auctionId;
						ai.Auction_Item_Name__c = opp.Auction_Donated_Item_Name__c;
						ai.Description__c = opp.Description;
						ai.Restrictions__c = opp.Auction_Donated_Item_Restrictions__c;

						// generate a free auction item id
						while (setItemId.contains(String.valueOf(itemId))) itemId++;
						ai.Name = String.valueOf(itemId++);

						listNewAuctionItem.add(new NewAuctionItem(ai, opp));
					}
				}
				return listNewAuctionItem;
			} catch (Exception e) {
				ApexPages.addMessages(e);
				return new List<NewAuctionItem>();
			}
		}
		set;
	}				
	
	// list of all fieldnames for Auction Items.
	private List<String> listStrAIFields {
		get {
			if (listStrAIFields == null) {
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Auction_Item__c.fields.getMap();
				listStrAIFields = new List<String>();
				listStrAIFields.addAll(mapS.keySet());  
			}
			return listStrAIFields;
		}
		set;
	}
	
	// so we can throw an exception with an error message	
 	private class MyException extends Exception {}
	
	// action method to create the auction items			
	public PageReference Convert() {
		List<Auction_Item__c> listAI = new List<Auction_Item__c>();
		List<Auction_Item_Piece__c> listAIP = new List<Auction_Item_Piece__c>();

		Savepoint sp = Database.setSavepoint();
		try {
			UTIL_Describe.checkObjectCreateAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'));
			UTIL_Describe.checkObjectCreateAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item_Piece__c'));

			// first create the Auction Item's
			for (NewAuctionItem nai : listNewAuctionItem) {
				if (nai.isChecked) {
					// in order to handle the insert of AI's succeeding, but 
					// then a later operation causing us to rollback,
					// we have to clone the AI's so their ID won't get set
					// by the insert!
					Auction_Item__c ai = new Auction_Item__c();
					AUC_AuctionMaintenance.CloneObject(nai.ai, ai, listStrAIFields);
					listAI.add(ai);
				}
			}
			insert listAI;
			
			// now create the Auction Item Pieces
			Integer iAI = 0;
			for (NewAuctionItem nai : listNewAuctionItem) {
				if (nai.isChecked) {
					Auction_Item_Piece__c aip = new Auction_Item_Piece__c();
					aip.Auction_Item__c = listAI[iAI++].Id;
					aip.Opportunity__c = nai.donatedItem.Id;
					if (nai.quantity == null || nai.quantity <= 0) {
                		throw (new MyException(nai.ai.Auction_Item_Name__c + ': Quantity cannot be less than one.'));												
					}
					if (nai.quantity > nai.donatedItem.Number_Available__c) {
                		throw (new MyException(nai.ai.Auction_Item_Name__c + 
                			': Quantity cannot be more than the number available (' + nai.donatedItem.Number_Available__c + ').'));						
					}
					aip.Quantity__c = nai.quantity;
					if (nai.donatedItem.Amount == null || nai.donatedItem.Number_of_Items__c == null) {
						aip.Actual_FMV__c = 0;
					} else {
						aip.Actual_FMV__c = (nai.donatedItem.Amount / nai.donatedItem.Number_of_Items__c) * aip.Quantity__c;
					}
					listAIP.add(aip);
				}
			}
			insert listAIP;
			
			strConvertResult = listAIP.size() + ' Auction Items were created.  The list has been refreshed to show remaining Donated Items.';
			listNewAuctionItem = null;
        } catch (Exception e) {
        	// undo our partially saved state
        	Database.rollback(sp);        				
			strConvertResult = 'Errors occurred: ';
            ApexPages.addMessages(e);            
        }

		return null;
	}

	// cancel the page and return to our caller. 
	public PageReference Cancel() {
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if (retURL == null || retURL == '') {
			retURL = '/apex/GW_Auctions__AuctionItems';
		}
		PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
        
	}
}