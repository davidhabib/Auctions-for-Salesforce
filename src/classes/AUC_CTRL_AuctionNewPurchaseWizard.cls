// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewPurchaseWizard {
	
	// constructor 
	public AUC_CTRL_AuctionNewPurchaseWizard() {

		checkFLS();
		
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
				
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;
		} else if (auctionId == null && listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = null;
			strSaveResults = 'You must specify an Auction before trying to create new purchases.';
		}
		auctionMaintenance.auctionId = auctionId;
		
		// handle the no auction case
		if (auctionId == null) {
			strSaveResults = 'You must first create an Auction before using this page.';
		}
		
		// force lists to get loaded to display any errors up front.
		List<SelectOption> lso = listSOLookupBidNumbers;
		lso = listSOLookupAuctionItems;
	}

	// check Field Level Security and object permissions on all objects and fields this page uses
	private void checkFLS() {
		UTIL_Describe.checkFieldReadAccess('CampaignMember', UTIL_Describe.StrTokenNSPrefix('Bid_Number__c'));
		UTIL_Describe.checkFieldReadAccess('Contact', 'Name');

		UTIL_Describe.checkReadAccess(UTIL_Describe.StrTokenNSPrefix('Auction_Item__c'), new Set<String>{
			'Name',
			UTIL_Describe.StrTokenNSPrefix('Auction_Item_Name__c')
		});

		UTIL_Describe.checkCreateAccess('Opportunity', new Set<String>{
			'Name',
			'StageName',
			'Amount',
			'CampaignId',
			'RecordTypeId',
			'AccountId',
			'Description',
			UTIL_Describe.StrTokenNSPrefix('Auction_Item_Purchased__c'),
			UTIL_Describe.StrTokenNSPrefix('Bid_Number__c'),
			UTIL_Describe.StrTokenNSPrefix('Auction_Non_Deductible_Amount__c')
		});
	}

	private AUC_AuctionMaintenance auctionMaintenance;
	
	public Id campaignIdAuctionAttendees {
		get { return auctionMaintenance.campaignIdAuctionAttendees;	}
	}
		
 	// the currently selected Auction
	public Id auctionId { get; set; }
	
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions { get; set; }
	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		listAuctionPurchasedItems = null;
		listSOLookupBidNumbers = null;
		listSOLookupBidNumbers2 = null;
		listSOLookupAuctionItems = null;
		listSOLookupAuctionItems2 = null;
		setAuctionItemIdPurchased = null;
		auctionMaintenance.auctionId = auctionId;
		strSaveResults = null;
		return null;
	}

	// filler function for the hidden listbox of all auction attendees, and their bid numbers.	 
	public List<SelectOption> listSOLookupBidNumbers {
		get {
			if (listSOLookupBidNumbers != null) {
				return listSOLookupBidNumbers;
			}
			listSOLookupBidNumbers = new List<SelectOption>();
			try {
				listSOLookupBidNumbers.add(new SelectOption('', ''));
				Integer cCM = 0;
				for (List<CampaignMember> listCM : [
					SELECT Bid_Number__c, Contact.Name, Contact.Id, Id
					FROM CampaignMember
					WHERE CampaignId = :campaignIdAuctionAttendees AND ContactId <> NULL AND Status <> 'RSVP No'
					ORDER BY Contact.LastName, Contact.FirstName
				]) {
					for (CampaignMember cm : listCM) {
						String strBidNumber = (cm.Bid_Number__c == null ? '' : String.valueOf(Integer.valueOf(cm.Bid_Number__c)));
						cCM++;
						if (cCM < 1000) {
							listSOLookupBidNumbers.add(new SelectOption(cm.Contact.Id, strBidNumber + ': ' + cm.Contact.Name));
						} else if (cCM < 2000) {
							if (listSOLookupBidNumbers2 == null) {
								listSOLookupBidNumbers2 = new List<SelectOption>();
							}
							listSOLookupBidNumbers2.add(new SelectOption(cm.Contact.Id, strBidNumber + ': ' + cm.Contact.Name));
						} else {
							strSaveResults = 'This page can only display the first 2000 contacts from the Attendees campaign whose status is different than "RSVP No". ' +
								' You should change the status of non-attendees to "RSVP No" in order to have this page list all the contacts who actually attended.';
							return listSOLookupBidNumbers;
						}
					}
				}
				return listSOLookupBidNumbers;
			} catch (Exception ex) {
				ApexPages.addMessages(ex);
				return listSOLookupBidNumbers;
			}
		}
		private set;
	}		

	// in order to handle more than 1000 attendees, we support a second list of bid numbers.
	public List<SelectOption> listSOLookupBidNumbers2 { get; set; }
		
	// filler function for the hidden listbox of all auction items.	 
	public List<SelectOption> listSOLookupAuctionItems {
		get {
			if (listSOLookupAuctionItems != null) {
				return listSOLookupAuctionItems;
			}
			listSOLookupAuctionItems = new List<SelectOption>();
			try {
				listSOLookupAuctionItems.add(new SelectOption('', ''));
				Integer cCM = 0;

				for (List<Auction_Item__c> listAI : [
					SELECT Id, Name, Auction_Item_Name__c
					FROM Auction_Item__c
					WHERE (Auction__c = :auctionId AND (Id NOT IN :setAuctionItemIdPurchased OR Allow_Multiple_Purchases__c = TRUE))
					ORDER BY Name, Auction_Item_Name__c
				]) {
					for (Auction_Item__c ai : listAI) {
						cCM++;
						if (cCM < 1000) {
							listSOLookupAuctionItems.add(new SelectOption(ai.Id, ai.Name + ': ' + ai.Auction_Item_Name__c));
						} else if (cCM < 2000) {
							if (listSOLookupAuctionItems2 == null) {
								listSOLookupAuctionItems2 = new List<SelectOption>();
							}
							listSOLookupAuctionItems2.add(new SelectOption(ai.Id, ai.Name + ': ' + ai.Auction_Item_Name__c));
						} else {
							strSaveResults = 'This page can only display the first 2000 Auction Items. ';
							return listSOLookupAuctionItems;
						}
					}
				}
				return listSOLookupAuctionItems;
			} catch (Exception ex) {
				ApexPages.addMessages(ex);
				return listSOLookupBidNumbers;
			}
		}
		private set;
	}		

	// in order to handle more than 1000 auction items, we support a second list of auction items.	 
	public List<SelectOption> listSOLookupAuctionItems2 { get; set; }

	// status string for reporting the results of saving.
    public String strSaveResults { get; set; }
    
	// the set of items already purchased 
	private Set<Id> setAuctionItemIdPurchased {
		get {
			if (setAuctionItemIdPurchased == null) {
				// see what has already been purchased
				List<Opportunity> listPurchaseOpp = [SELECT Auction_Item_Purchased__c FROM Opportunity 
					WHERE RecordTypeId = :AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem 
						AND CampaignId = :campaignIdAuctionAttendees];
				setAuctionItemIdPurchased = new Set<Id>();
				for (Opportunity opp : listPurchaseOpp) {
					setAuctionItemIdPurchased.add(opp.Auction_Item_Purchased__c);
				}						
			}
			return setAuctionItemIdPurchased;
		}
		set;
	}
         
    // The list of new Auction Purchased Items to create (opps).
    public List<AUC_PurchaseOpportunity> listAuctionPurchasedItems {
	    get {
		    if (listAuctionPurchasedItems == null) {
                listAuctionPurchasedItems = new List<AUC_PurchaseOpportunity>();
			    for (Integer i = 0; i < AUC_AuctionConstants.CROWS_PURCHASE_GRID; i++) {
				    AUC_PurchaseOpportunity apo = new AUC_PurchaseOpportunity();
				    apo.opp.CloseDate = System.today();
				    apo.IsPayNow = false; // no longer have Paid checkbox default to true.
				    listAuctionPurchasedItems.add(apo);
			    }
		    }
		    return listAuctionPurchasedItems;
	    }
	    private set;
    }
 
 	private class MyException extends Exception {}
 
    //create the new Auction Purchases
    public PageReference CreateAuctionPurchases() {
        try {
	        strSaveResults = 'Starting Save...';
	        Integer cOpps = 0;
	        List<Opportunity> listOppsToCreate = new List<Opportunity>();
	        List<OpportunityContactRole> listCRToCreate = new List<OpportunityContactRole>();

        	// do any bulk soqls we can up front to avoid too many calls.
        	Set<Id> setAuctionItemId = new Set<Id>();        	
        	Set<Id> setContactId = new Set<Id>();
            for (AUC_PurchaseOpportunity apo : listAuctionPurchasedItems) {
                if (apo.contactId != null && apo.contactId != '' && apo.opp.Auction_Item_Purchased__c != null) {
					setAuctionItemId.add(apo.opp.Auction_Item_Purchased__c);
					setContactId.add(apo.contactId);
                }
            }
            // cache all the auction items
            Map<Id, Auction_Item__c> mapIdtoAuctionItem = new Map<Id, Auction_Item__c>();
            List<Auction_Item__c> listAuctionItem = [SELECT Id, Name, Auction_Item_Name__c, Allow_Multiple_Purchases__c, 
                		Treat_Purchase_as_Gift__c, Fair_Market_Value__c, Description__c, Restrictions__c 
                		FROM Auction_Item__c 
                		WHERE Id IN :setAuctionItemId];
            for (Auction_Item__c ai : listAuctionItem) {
            	mapIdtoAuctionItem.put(ai.Id, ai);
            }
            // cache all the contacts' accounts.
            Map<Id, Id> mapContactIdtoAccountId = new Map<Id, Id>();
            if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
            	List<Contact> listCon = [SELECT Id, AccountId FROM Contact WHERE Id IN :setContactId];
            	for (Contact con : listCon) {
            		mapContactIdtoAccountId.put(con.Id, con.AccountId);
            	}            	
            }
            // cache all the contacts' bid numbers.
            Map<Id, Decimal> mapContactIdtoBidNumber = new Map<Id, Decimal>();
            List<CampaignMember> listCM = [SELECT Bid_Number__c, ContactId FROM CampaignMember
					WHERE CampaignId = :campaignIdAuctionAttendees AND ContactId IN :setContactId];
            for (CampaignMember cm : listCM) {
            	mapContactIdtoBidNumber.put(cm.ContactId, cm.Bid_Number__c);
            }
                    	  	
        	// loop through the opps of the grid, and save the valid ones.
            for (AUC_PurchaseOpportunity apo : listAuctionPurchasedItems) {
                strSaveResults = 'Saved ' + cOpps + ' auction purchases...';                               
                if (apo.contactId != null && apo.contactId != '' && apo.opp.Auction_Item_Purchased__c != null) {
                	
                	// ensure Amount specified (allowing 0)
                	if (apo.strAmount == null || apo.strAmount == '') {
                		throw (new MyException('Amount not specified'));
                	}
                	apo.opp.Amount = Decimal.valueOf(apo.strAmount);
                	
                	String strOppTypeName;
                	apo.opp.CampaignId = campaignIdAuctionAttendees;
                	Auction_Item__c item = mapIdtoAuctionItem.get(apo.opp.Auction_Item_Purchased__c);

	                if (item == null) {
		                throw (new MyException('Item not specified'));
	                }

                	// prevent duplicate purchases
                	if (setAuctionItemIdPurchased.contains(item.Id) && item.Allow_Multiple_Purchases__c == false)  {
                		throw (new MyException(item.Name + ': ' + item.Auction_Item_Name__c + ' has already been purchased.'));                		
                	}
                	setAuctionItemIdPurchased.add(item.Id);

                	if (item.Treat_Purchase_as_Gift__c) {
		                apo.opp.RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionGift;
		                strOppTypeName = AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionGift;
                	} else {
		                apo.opp.RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem;
		                strOppTypeName = AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionPurchasedItem;
                	} 
	                apo.opp.Name = apo.strBidderName + ' ' + String.valueOf(AUC_AuctionMaintenance.YearOfAuctionId(auctionMaintenance.auctionId)) + ' ' + strOppTypeName;
	                if (apo.IsPayNow) { 
						AUC_AuctionMaintenance.setOpportunityStageClosed(apo.opp);
	                } else {
	                	apo.opp.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
	                } 
	                
		            // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
					// if so, we need to set the Opp's Account to make the rollups work.
					if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
						apo.opp.AccountId = mapContactIdtoAccountId.get(apo.contactId);
					}
				
	                apo.opp.Auction_Non_Deductible_Amount__c = item.Fair_Market_Value__c;
	                apo.opp.Description = (item.Description__c != null ? item.Description__c : '') + 
	                	(item.Restrictions__c != null ? '\nRestrictions: ' + item.Restrictions__c : '');
					apo.opp.Bid_Number__c = mapContactIdtoBidNumber.get(apo.contactId);
					AUC_AuctionMaintenance.didUpdateOppWithNPSPOCRData(apo.opp, apo.contactId);	                	
	                listOppsToCreate.add(apo.opp);
  
  	                OpportunityContactRole cr = new OpportunityContactRole();
	                cr.OpportunityId = apo.opp.Id;
	                cr.ContactId = apo.contactId;
	                cr.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
	                cr.IsPrimary = true;
	                listCRToCreate.add(cr);
  	                	                
	                // Note that purchasers are already on the Attendee campaign, since we require their bid number.
	                // thus there is no reason to try to add them to the campaign.

	                cOpps++;                
                }
            }
        	if (listOppsToCreate.size() > 0) {
        		insert listOppsToCreate;
				// set OppId's
				for (Integer i = 0; i < listOppsToCreate.size(); i++) {
					listCRToCreate[i].OpportunityId = listOppsToCreate[i].Id;
				}
				AUC_AuctionMaintenance.saveOppContactRoles(listCRToCreate);
        	}
        	strSaveResults = 'Successfully saved ' + cOpps + ' auction purchase(s).';      
            listAuctionPurchasedItems = null;
            setAuctionItemIdPurchased = null;   
            listSOLookupAuctionItems = null;
            
        } catch (Exception e) {
            strSaveResults = 'Error encountered while trying to save auction purchases.';
            ApexPages.addMessages(e);                        
            setAuctionItemIdPurchased = null;   
            return null;
        }
                
    return null;
	}

	public PageReference Cancel() {
		PageReference p = Page.AuctionPurchases;
        p.setRedirect(true);
        return p;
	}
}