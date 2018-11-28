// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewDonatedItemWizard {
	 
	// constructor for the class
	public AUC_CTRL_AuctionNewDonatedItemWizard() {
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String auctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
		
		// do any initialization which is not dependent on having an auctionId
		auctionMaintenance = new AUC_AuctionMaintenance();
		auctionItem = new Auction_Item__c();
		opp = new Opportunity(RecordTypeId=AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem);
		opp.CloseDate = System.today();
		opp.Number_of_Items__c = 1;
		AUC_AuctionMaintenance.setOpportunityStageClosed(opp);
		fCreateAuctionItem = false;	
		contactRole = new OpportunityContactRole();			
		
		// handle it if we don't have an auctionId passed in.
		if (auctionId != null && auctionId != '' && auctionId != 'null') {
			auctionMaintenance.auctionId = auctionId;	
			auctionItem.Auction__c = auctionId;
			opp.CampaignId = auctionMaintenance.campaignIdAuctionDonors;
		}
		
	}

	private AUC_AuctionMaintenance auctionMaintenance;
		
	// object to hold opportunity
	public Opportunity opp { get; set; } 
	
	// we instantiate this object to get the Contact lookup field. And we also created it for the opp.
	public OpportunityContactRole contactRole { get; set; }
	
	// object to hold the auction item
	public Auction_Item__c auctionItem { get; set; }
	
	public Boolean fCreateAuctionItem { get; set; }
	public String StrFCreateAuctionItem { get { return String.valueOf(fCreateAuctionItem); }}
		
	// status string for reporting the results of saving.
    public String strSaveResults { get; set; }    
	
	// called by the page when the user checks/unchecks the Create Auction Item checkbox.		
	public PageReference ToggleCreateAuctionItem() {		
		if (fCreateAuctionItem) {
			if (auctionItem.Auction_Item_Name__c == null) auctionItem.Auction_Item_Name__c = opp.Auction_Donated_Item_Name__c;
			if (auctionItem.Description__c == null) auctionItem.Description__c = opp.Description; 
			if (auctionItem.Restrictions__c == null) auctionItem.Restrictions__c = opp.Auction_Donated_Item_Restrictions__c;
		}
		return null;
	}	

	public PageReference Cancel() {
		PageReference p = new PageReference('/apex/AuctionDonatedItems');
        p.setRedirect(true);
        return p;
	}
		
	public PageReference Save() {
	    strSaveResults = 'Starting Save...';
		
		try {
			// since we are using apex:inputField for all Opp fields, we don't need to test each field's permissions
			UTIL_Describe.checkObjectCreateAccess('Opportunity');
			UTIL_Describe.checkObjectUpdateAccess('Opportunity');
			UTIL_Describe.checkCreateAccess('CampaignMember', new Set<String> {
				'ContactId',
				'CampaignId',
				'Status'
			});
			// since we are using apex:inputField for all Auction Item fields, we don't need to test each field's permissions
			UTIL_Describe.checkObjectCreateAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'));
			UTIL_Describe.checkCreateAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item_Piece__c'), new Set<String>{
				UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'),
				UTIL_Describe.StrTokenNSPrefix('Opportunity__c'),
				UTIL_Describe.StrTokenNSPrefix('Quantity__c')
			});

			Contact contact = [SELECT Name, AccountId FROM Contact WHERE Id=:contactRole.ContactId];
			String strDonor = contact.Name;
			String strDonorRole = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
			Account org;	
			if (opp.AccountId != null) {
				org = [SELECT Name FROM Account WHERE Id=:opp.AccountId];
				strDonor = org.Name;
				strDonorRole = AUC_AuctionConstants.OPP_ORG_GIFT_DONOR_ROLE;
			} else {
				// see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
				// if so, we need to set the Opp's Account to make the rollups work.
				if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
					opp.AccountId = contact.AccountId;
				}
			}
			opp.Name = strDonor + ' ' + String.valueOf(AUC_AuctionMaintenance.YearOfAuctionId(auctionMaintenance.auctionId)) + AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionDonatedItem;
			// can't assume opp is new, in case of later error, and then a resave.
			if (opp.Id == null) {
				AUC_AuctionMaintenance.didUpdateOppWithNPSPOCRData(opp, contactRole.ContactId);
				insert opp;
				
				// create/update the contactRole for the donor
				contactRole.OpportunityId = opp.Id;
				contactRole.Role = strDonorRole;
				contactRole.IsPrimary = true;
				AUC_AuctionMaintenance.saveOppContactRole(contactRole);

				// add the donor to the campaign
				// handle that they might already be on the campaign!
				try {
					CampaignMember cm = new CampaignMember();
					cm.ContactId = contactRole.ContactId;
					cm.CampaignId = opp.CampaignId;
	                cm.Status = 'Donated';				
					insert cm;
				} catch (Exception e) {}
			} else {
				update opp;	
			}
			
					
			if (fCreateAuctionItem) {
				if (auctionItem.Donor_Recognition__c == null) {
					auctionItem.Donor_Recognition__c = strDonor;
				}
				insert auctionItem;		
				Auction_Item_Piece__c piece = new Auction_Item_Piece__c();
				piece.Auction_Item__c = auctionItem.Id;
				piece.Opportunity__c = opp.Id;
				piece.Quantity__c = opp.Number_of_Items__c;
				if (piece.Quantity__c == null) piece.Quantity__c = 1;
				// piece.Actual_FMV__c = opp.Amount; workflow rule now sets this field automatically.
				insert piece; 
			}
					 
			PageReference p = new PageReference('/apex/AuctionDonatedItems');
	        p.setRedirect(true);
	        return p;
        
        } catch (Exception e) {
			// note that we intentionally did not use savepoint/rollback here, to avoid having
			// to recreate opp and auctionItem (since we can't clear their Id's to null).
			if (opp.Id == null) {
				strSaveResults = 'Error encountered while trying to save the auction donated item.  ';
			} else {
				strSaveResults = 'The auction donated item has been saved, but errors were encountered trying to save the related auction item.  ';
			}
            ApexPages.addMessages(e);
            return null;
        }	   
	}
}