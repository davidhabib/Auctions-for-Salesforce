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
	private String strQueryParams;

	//constructor
	public AUC_CTRL_AuctionNewItemPieceWizard (ApexPages.StandardController controller) {

		checkFLS();

		//get record from standard controller
		stdController = controller;
        this.aip = (Auction_Item_Piece__c)controller.getRecord();

        // Keep track of any inbound query string parameters so they can be passed along when creating a new record
        List<String> pageUrl = ApexPages.currentPage().getUrl().split('\\?');
		if (pageUrl.size() > 1) {
			strQueryParams = pageUrl[1];
		}

        // we are getting called from either an Auction Item, or a Donated Item.
        // figure out which one, and then derive the auctionId.
        if (aip.Auction_Item__c != null) {
        	List<Auction_Item__c> listAI = [SELECT Auction__c FROM Auction_Item__c WHERE Id=:aip.Auction_Item__c];
        	auctionId = listAI[0].Auction__c;
        	auctionItemId = aip.Auction_Item__c;
        } 

        if (aip.Opportunity__c != null) {
        	List<Campaign> listCmp = [SELECT Auction__c FROM Campaign WHERE Id IN
        		(SELECT CampaignId FROM Opportunity WHERE Id = :aip.Opportunity__c) ];
        	auctionId = listCmp[0].Auction__c;
	        oppDonatedItemId = aip.Opportunity__c;
	        // NOTE: we correctly set the oppId, but if there are no items left for this donation,
	        // it won't appear in the picklist of donated items, and thus it will come up empty.
        } 
        			
		auctionMaintenance = new AUC_AuctionMaintenance();
		auctionMaintenance.auctionId = auctionId;
	}

	// check Field Level Security and object permissions on all objects and fields this page uses
	private void checkFLS() {
		UTIL_Describe.checkReadAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item_Piece__c'), new Set<String>{
			'Name',
			UTIL_Describe.StrTokenNSPrefix('Actual_FMV__c'),
			UTIL_Describe.StrTokenNSPrefix('Auction_Donated_Item_Name__c'),
			UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'),
			UTIL_Describe.StrTokenNSPrefix('Description__c'),
			UTIL_Describe.StrTokenNSPrefix('Estimated_FMV__c'),
			UTIL_Describe.StrTokenNSPrefix('Opportunity__c'),
			UTIL_Describe.StrTokenNSPrefix('Quantity__c')
		});
	}
	
	// the list of opps to put in the Auction Donated Item dropdown
	public List<SelectOption> listSODonatedItems {
		get {
			try {
				if (listSODonatedItems == null) {
					listSODonatedItems = new List<SelectOption>();
					UTIL_Describe.checkReadAccess('Opportunity', new Set<String>{
						'Amount',
						UTIL_Describe.StrTokenNSPrefix('Auction_Donated_Item_Name__c'),
						UTIL_Describe.StrTokenNSPrefix('Number_Available__c'),
						UTIL_Describe.StrTokenNSPrefix('Number_of_Items__c')
					});
					listSODonatedItems.add(new SelectOption('', ''));
					for (Opportunity opp : [
						SELECT Auction_Donated_Item_Name__c, Id, Number_Available__c, Number_of_Items__c, Amount
						FROM Opportunity
						WHERE RecordTypeId = :AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem
						AND Number_Available__c > 0
						AND CampaignId = :auctionMaintenance.campaignIdAuctionDonors
						ORDER BY Auction_Donated_Item_Name__c DESC
						LIMIT 999
					]) {
						if (opp.Number_of_Items__c > 0) {
							Decimal cost = ((opp.Amount == null) ? 0 : opp.Amount) / opp.Number_of_Items__c;
							listSODonatedItems.add(new SelectOption(opp.Id, opp.Auction_Donated_Item_Name__c + ' ('
								+ Integer.valueOf(opp.Number_Available__c) + ' available at $'
								+ String.valueOf(cost.setScale(2)) + ' each)'));
						}
					}
				}
				return listSODonatedItems;
			} catch (Exception ex) {
				ApexPages.addMessages(ex);
				// for some reason, the addMessage doesn't work in this scenario (maybe due to it being a getter?)
				// so let's also put the error in the select list!
				listSODonatedItems.add(new SelectOption('', ex.getMessage()));
				return listSODonatedItems;
			}
		}
		private set;
	}

	// the list of Auction Items to put in the Auction Item dropdown
	public List<SelectOption> listSOAuctionItems {
		get {
			try {
				if (listSOAuctionItems == null) {
					listSOAuctionItems = new List<SelectOption>();
					UTIL_Describe.checkReadAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'), new Set<String>{
						'Name',
						UTIL_Describe.StrTokenNSPrefix('Auction_Item_Name__c')
					});
					listSOAuctionItems.add(new SelectOption('', ''));
					for (Auction_Item__c ai : [
						SELECT Id, Name, Auction_Item_Name__c
						FROM Auction_Item__c
						WHERE Auction__c = :auctionId
						ORDER BY Name
						LIMIT 999
					]) {
						listSOAuctionItems.add(new SelectOption(ai.Id, ai.Name + ' - ' + ai.Auction_Item_Name__c));
					}
				}
				return listSOAuctionItems;
			} catch (Exception ex) {
				ApexPages.addMessages(ex);
				// for some reason, the addMessage doesn't work in this scenario (maybe due to it being a getter?)
				// so let's also put the error in the select list!
				listSOAuctionItems.add(new SelectOption('', ex.getMessage()));
				return listSOAuctionItems;
			}
		}
		private set;
	}

	public PageReference Save() {
		aip.Auction_Item__c = auctionItemId;
		aip.Opportunity__c = oppDonatedItemId;
		if (stdController.save() != null) {
			return new PageReference('/' + aip.Auction_Item__c);
		}
		return null;
	}
	
	public PageReference SaveAndNew() {
		if (Save() != null) {
			// there is no action method on the standard controller for New, so we must hack this.
			ApexPages.currentPage().setRedirect(true);
            return new PageReference('/' + aip.getSObjectType().getDescribe().getKeyPrefix() + '/e?' + strQueryParams);					
		}
		return null;
	}

	// under LEX, stdController.cancel didn't go back to the auction item
	// so we force it when we can.
	public PageReference Cancel() {
		ApexPages.currentPage().setRedirect(true);
		if (aip.Auction_Item__c != null) {
			return new PageReference('/' + aip.Auction_Item__c);
		}
		return stdController.cancel();
	}
}