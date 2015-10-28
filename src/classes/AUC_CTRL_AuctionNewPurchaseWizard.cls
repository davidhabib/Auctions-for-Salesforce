// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewPurchaseWizard {
	
	// constructor 
	public AUC_CTRL_AuctionNewPurchaseWizard() {
		
		// get the current auction we were invoked from, and find & set the appropriate campaign.
		// NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
		// was set for the parameter, which cannot be assigned to type Id.
		String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
				
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;
		} else if (auctionId == null && listSOAuctions != null && listSOAuctions.size() > 1) {
			//auctionId = listSOAuctions[1].getValue();
			auctionId = null;
			strSaveResults = 'You must specify an Auction before trying to create new purchases.';
		}
		auctionMaintenance.auctionId = auctionId;
		
		// handle the no auction case
		if (auctionId == null) {
			strSaveResults = 'You must first create an Auction before using this page.';
		}
		
		// force lists to get loaded to display any errors up front.
		list<SelectOption> lso = listSOLookupBidNumbers;
		lso = listSOLookupAuctionItems;
	}
		
	private AUC_AuctionMaintenance auctionMaintenance;
	
	public Id campaignIdAuctionAttendees {
		get { return auctionMaintenance.campaignIdAuctionAttendees;	}
	}
		
 	// the currently selected Auction
	public Id auctionId { get; set; }
	
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions { get; set; }
	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		//mapBidders.clear();
		//mapAuctionItems.clear();
		listAuctionPurchasedItems.clear();
		auctionMaintenance.auctionId = auctionId;
		strSaveResults = null;
		return null;
	}

	// filler function for the hidden listbox of all auction attendees, and their bid numbers.	 
	public list<SelectOption> listSOLookupBidNumbers {
		get {
			if (listSOLookupBidNumbers != null) return listSOLookupBidNumbers;
			listSOLookupBidNumbers = new list<SelectOption>();
			listSOLookupBidNumbers.add(new SelectOption('', ''));
			integer cCM = 0;
			for (list<CampaignMember> listCM : [select Bid_Number__c, Contact.Name, Contact.Id, Id from CampaignMember 
					where CampaignId=:campaignIdAuctionAttendees and contactId<>null and Status<>'RSVP No' order by Contact.LastName, Contact.FirstName]) {
				for (CampaignMember cm : listCM) {
					String strBidNumber = (cm.Bid_Number__c == null ? '' : string.valueOf(integer.valueOf(cm.Bid_Number__c)));
					cCM++;
					if (cCM < 1000) {
						listSOLookupBidNumbers.add(new SelectOption(cm.Contact.Id, strBidNumber + ': ' + cm.Contact.Name));
					} else if (cCm < 2000) {
						if (listSOLookupBidNumbers2 == null) listSOLookupBidNumbers2 = new list<SelectOption>();
						listSOLookupBidNumbers2.add(new SelectOption(cm.Contact.Id, strBidNumber + ': ' + cm.Contact.Name));						
					} else {
						strSaveResults = 'This page can only display the first 2000 contacts from the Attendees campaign whose status is different than "RSVP No". ' +
							' You should change the status of non-attendees to "RSVP No" in order to have this page list all the contacts who actually attended.';
						return listSOLookupBidNumbers;					
					}
				}
			}		
			return listSOLookupBidNumbers;
		}
		set;
	}		

	// in order to handle more than 1000 attendees, we support a second list of bid numbers.
	public list<SelectOption> listSOLookupBidNumbers2 { get; set; }
		
	// filler function for the hidden listbox of all auction items.	 
	public list<SelectOption> listSOLookupAuctionItems {
		get {
			if (listSOLookupAuctionItems != null) return listSOLookupAuctionItems;
			listSOLookupAuctionItems = new list<SelectOption>();
			listSOLookupAuctionItems.add(new SelectOption('', ''));
			integer cCM = 0;
					
			for (list<Auction_Item__c> listAI : [select Id, Name, Auction_Item_Name__c from Auction_Item__c 
				where (Auction__c = :auctionId and (Id not in :setAuctionItemIdPurchased or Allow_Multiple_Purchases__c = true))
					order by Name, Auction_Item_Name__c]) {
				for (Auction_Item__c ai : listAI) {
					cCM++;
					if (cCM < 1000) {
						listSOLookupAuctionItems.add(new SelectOption(ai.Id, ai.Name + ': ' + ai.Auction_Item_Name__c));
					} else if (cCM < 2000) {
						if (listSOLookupAuctionItems2 == null) listSOLookupAuctionItems2 = new list<SelectOption>();
						listSOLookupAuctionItems2.add(new SelectOption(ai.Id, ai.Name + ': ' + ai.Auction_Item_Name__c));
					} else {
						strSaveResults = 'This page can only display the first 2000 Auction Items. ';
						return listSOLookupAuctionItems;											
					}
				}
			}		
			return listSOLookupAuctionItems;
		}
		set;
	}		

	// in order to handle more than 1000 auction items, we support a second list of auction items.	 
	public list<SelectOption> listSOLookupAuctionItems2 { get; set; }

	// status string for reporting the results of saving.
    public String strSaveResults { get; set; }
    
	// the set of items already purchased 
	private set<ID> setAuctionItemIdPurchased {
		get {
			if (setAuctionItemIdPurchased == null) {
				// see what has already been purchased
				list<Opportunity> listPurchaseOpp = [select Auction_Item_Purchased__c from Opportunity 
					where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionPurchasedItem 
						and campaignId = :campaignIdAuctionAttendees];
				setAuctionItemIdPurchased = new set<ID>();
				for (Opportunity opp : listPurchaseOpp) {
					setAuctionItemIdPurchased.add(opp.Auction_Item_Purchased__c);
				}						
			}
			return setAuctionItemIdPurchased;
		}
		set;
	}
         
    // The list of new Auction Purchased Items to create (opps).
    private list<AUC_PurchaseOpportunity> listAuctionPurchasedItems = new list<AUC_PurchaseOpportunity>();
    
    public list<AUC_PurchaseOpportunity> getAuctionPurchasedItems() {
        if (listAuctionPurchasedItems.size() == 0) {            
            for (integer i = 0; i < AUC_AuctionConstants.CROWS_PURCHASE_GRID; i++) { 
                AUC_PurchaseOpportunity apo = new AUC_PurchaseOpportunity();
                apo.opp.CloseDate = system.today();
                apo.IsPayNow = false; // no longer have Paid checkbox default to true.
                listAuctionPurchasedItems.add(apo);
            } 
        }
        return listAuctionPurchasedItems;
    }     
 
 	private class MyException extends Exception {}
 
    //create the new Auction Purchases
    public PageReference CreateAuctionPurchases() {
        strSaveResults = 'Starting Save...';
        integer cOpps = 0;
		List<Opportunity> listOppsToCreate = new List<Opportunity>();
		List<OpportunityContactRole> listCRToCreate = new List<OpportunityContactRole>();
	        
        try {   
        	// do any bulk soqls we can up front to avoid too many calls.
        	set<ID> setAuctionItemId = new set<ID>();        	
        	set<ID> setContactId = new set<ID>();
            for (AUC_PurchaseOpportunity apo : listAuctionPurchasedItems) {
                if (apo.contactId != null && apo.contactId != '' && apo.opp.Auction_Item_Purchased__c != null) {
					setAuctionItemId.add(apo.opp.Auction_Item_Purchased__c);
					setContactId.add(apo.contactId);
                }
            }
            // cache all the auction items
            map<ID, Auction_Item__c> mapIDtoAuctionItem = new map<ID, Auction_Item__c>();
            list<Auction_Item__c> listAuctionItem = [select Id, Name, Auction_Item_Name__c, Allow_Multiple_Purchases__c, 
                		Treat_Purchase_as_Gift__c, Fair_Market_Value__c, Description__c, Restrictions__c 
                		from Auction_Item__c 
                		where Id in :setAuctionItemId];
            for (Auction_Item__c ai : listAuctionItem) {
            	mapIDToAuctionItem.put(ai.Id, ai);
            }
            // cache all the contacts' accounts.
            map<ID, ID> mapContactIdtoAccountId = new map<ID, ID>();
            if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
            	list<Contact> listCon = [select Id, AccountId from Contact where Id in :setContactId];
            	for (Contact con : listCon) {
            		mapContactIdtoAccountId.put(con.Id, con.AccountId);
            	}            	
            }
            // cache all the contacts' bid numbers.
            map<ID, decimal> mapContactIdtoBidNumber = new map<ID, decimal>();
            list<CampaignMember> listCM = [select Bid_Number__c, contactId from CampaignMember 
					where CampaignId = :campaignIdAuctionAttendees and contactId in :setContactId];
            for (CampaignMember cm : listCM) {
            	mapContactIdtoBidNumber.put(cm.contactId, cm.Bid_Number__c);
            }
                    	  	
        	// loop through the opps of the grid, and save the valid ones.
            for (AUC_PurchaseOpportunity apo : listAuctionPurchasedItems) {
                strSaveResults = 'Saved ' + cOpps + ' auction purchases...';                               
                double BidderNum = apo.BidderNumber;
                //Contact c = mapBidders.get(BidderNum);
                //Auction_Item__c item = mapAuctionItems.get(apo.strAuctionItemID);
                if (apo.contactId != null && apo.contactId != '' && apo.opp.Auction_Item_Purchased__c != null) {
                	
                	// ensure Amount specified (allowing 0)
                	if (apo.strAmount == null || apo.strAmount == '') {
                		throw (new MyException('Amount not specified'));
                	}
                	apo.opp.Amount = decimal.valueOf(apo.strAmount);
                	
                	string strOppTypeName;
                	apo.opp.campaignId = campaignIdAuctionAttendees;
                	Auction_Item__c item = mapIDToAuctionItem.get(apo.opp.Auction_Item_Purchased__c);

                	// prevent duplicate purchases
                	if (setAuctionItemIdPurchased.contains(item.Id) && item.Allow_Multiple_Purchases__c == false)  {
                		throw (new MyException(item.Name + ': ' + item.Auction_Item_Name__c + ' has already been purchased.'));                		
                	}
                	setAuctionItemIdPurchased.add(item.Id);

                	if (item.Treat_Purchase_as_Gift__c) {
		                apo.opp.RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionGift;
		                strOppTypeName = AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionGift;
                	} else {
		                apo.opp.RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionPurchasedItem;
		                strOppTypeName = AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionPurchasedItem;
                	} 
	                apo.opp.Name = apo.strBidderName + ' ' + string.valueof(AUC_AuctionMaintenance.YearOfAuctionId(auctionMaintenance.auctionId)) + ' ' + strOppTypeName;
	                if (apo.IsPayNow) { 
	                	apo.opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;
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
        		insert listOppstoCreate;
        		
        		if (listCRToCreate.size() > 0) {
        			// because NPSP may have already created contact roles, depending on account model, and whether a given contact
        			// has a 1:1 account or a company account, we will check each Opp, to see if it needs a contact role or not.
        			list<OpportunityContactRole> listCR = new list<OpportunityContactRole>();
        			
        			// we used to do this with individual calls to fCreateOppContactRoles, but that is inefficient.
        			// query for all the contact roles in one soql
        			set<ID> setOppId = new set<ID>();
        			for (Opportunity opp : listOppstoCreate) {
        				setOppId.add(opp.Id);
        			}
			    	list<OpportunityContactRole> listCRExisting = [select Id, OpportunityId from OpportunityContactRole where IsPrimary=true and OpportunityId in :setOppId]; 
        			setOppId.clear();
        			for (OpportunityContactRole cr : listCRExisting) {
        				setOppId.add(cr.OpportunityId);
        			}
        			
	        		// now fixup the opp ids in the contact roles
	        		for (integer i = 0; i < cOpps; i++) {
	        			listCRTOCreate[i].OpportunityId = listOppsToCreate[i].Id;
	        			// see if anyone (NPSP) already created the ContactRole
	        			//if (AUC_AuctionConstants.fCreateOppContactRoles(listCRTOCreate[i].OpportunityId, listCRTOCreate[i].ContactId)) {
	        			if (!setOppId.contains(listCRTOCreate[i].OpportunityId)) {
	        				listCR.add(listCRToCreate[i]);
	        			}	        		
	        		}	
	        		insert listCR;
        		}
        	}
        	strSaveResults = 'Successfully saved ' + cOpps + ' auction purchase(s).';      
            listAuctionPurchasedItems.clear();  
            setAuctionItemIdPurchased = null;   
            listSOLookupAuctionItems = null;
            
        } catch (Exception e) {
            strSaveResults = 'Error encountered while trying to save auction purchases.  ';
            ApexPages.addMessages(e);                        
            setAuctionItemIdPurchased = null;   
            return null;
        }
                
    return null;
	}
	
	// we maintain a map of Bidder Number to Contact, both to display
	// the bidder's name, asyncronously, as well as to get the ContactId
	// to store in the opportunity we will create.
	/* we've deprecated use of the map, by using the hidden listbox on the client
	private map<Double, Contact> mapBidders = new map<Double, Contact>();
	private void LoadMapBidders() {
		Double BidderNum;
		for (AUC_PurchaseOpportunity apo : listAuctionPurchasedItems) {
			BidderNum = apo.BidderNumber;			
			if (BidderNum > 0) {
				Contact c = mapBidders.get(BidderNum);
				if (c == null) {
					list<Contact> listC = [select id, firstname, lastname from Contact 
						where id in (select ContactId from CampaignMember 
							where Bid_Number__c=:BidderNum and CampaignId=:auctionMaintenance.campaignIdAuctionAttendees)];
					if (listC.size() > 0) {
						c = listC[0];
						mapBidders.put(BidderNum, c);
					}
				}
				if (c == null) {
					apo.strBidderName = 'Bid Number ' + BidderNum.format() + ' not found.';
				} else {		
					apo.strBidderName = c.firstname + ' ' + c.lastname;
				}
			}
		}
	} 
 
 	// LoadBidder() is called by the OnChange event of any of the Bidder Number fields.
	// unfortunately, I couldn't figure out how to know which specific field changed, so 
	// we must update the map of Bidders looking at all bid numbers on the sheet, not just the new one entered.
	public PageReference LoadBidder() {
			LoadMapBidders();
	        return null;
    }
	*/
		
	// we maintain a map of AuctionItemID to AuctionItem, both to display
	// the item's name, asyncronously, as well as to get the AuctionItemId
	// to store in the opportunity we will create.
	/* we've deprecated use of the map, by using the hidden listbox on the client
	private map<string, Auction_Item__c> mapAuctionItems = new map<string, Auction_Item__c>();
	private void LoadMapAuctionItems() {
		for (AUC_PurchaseOpportunity apo : listAuctionPurchasedItems) {
			string strAuctionItemID = apo.strAuctionItemID;
			if (strAuctionItemID != null) {
				Auction_Item__c item = mapAuctionItems.get(strAuctionItemID);
				if (item == null) {
					list<Auction_Item__c> listItems = [select Id, Name, Fair_Market_Value__c, Auction_Item_Name__c, Treat_Purchase_as_Gift__c from Auction_Item__c where Auction__c=:auctionId and Name=:strAuctionItemID];
					if (listItems.size() > 0) {
						item = listItems[0];
						mapAuctionItems.put(strAuctionItemID, item);
					}
				}
				if (item == null) {
					apo.strAuctionItemName = 'Auction Item ' + strAuctionItemID + ' not found.';
				} else {		
					apo.strAuctionItemName = item.Auction_Item_Name__c;
				}
			}
		}
	} 
	
	// LoadAuctionItems() is called by the OnChange event of any of the AuctionItemID fields.
	// unfortunately, I couldn't figure out how to know which specific field changed, so 
	// we must update the map of AuctionItems looking at all AuctionItemIDs on the sheet, not just the new one entered.
	public PageReference LoadAuctionItem() {
			LoadMapAuctionItems();
	        return null;
    }
	*/
	
	public PageReference Cancel() {
		PageReference p = new PageReference('/apex/AuctionPurchases');
        p.setRedirect(true);
        return p;
	}
	
	//==================== TEST METHOD(s) ======================================    
    static testMethod void UnitTest() {
    	
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	   	    	
    	Auction_Item__c auctionitem = new Auction_Item__c (
    		Auction_Item_Name__c = 'Test Auction item',
    		Auction__c = auction.id
    	);
    	insert auctionitem;
    	auctionitem = [select Id, Name, Auction_Item_Name__c from Auction_Item__c where Id=:auctionitem.Id];
    	String strAIName = auctionitem.Name;
    	System.Assert(strAIName != null);
    	System.Debug('Auction Item ID/Name is ' + strAIName);
    	  	
    	Account acc = new Account(Name='My Test Account');
    	insert acc;
    	
    	Contact contact = new Contact(
    		Firstname = 'Johnny',
    		Lastname = 'Test',
    		AccountId = acc.Id
    	);
    	insert contact;
    	
    	CampaignMember campaignmember = new CampaignMember( 
    		CampaignId = campaign.id,
    		ContactId = contact.id,
    		Bid_Number__c = 123
    	);
    	insert campaignmember;
  		
		//point to our VF page
		Test.setCurrentPageReference(new PageReference('Page.NewAuctionPurchaseWizard'));
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewPurchaseWizard controller = new AUC_CTRL_AuctionNewPurchaseWizard();
				
		list<SelectOption> listso = controller.listSOAuctions;
		system.Assert(listso.size() > 0);
		
		// select the current auction
		controller.auctionId = auction.id;
		controller.ChangeAuction();
		system.AssertEquals(null, controller.strSaveResults);	
		System.Assert(controller.listSOLookupBidNumbers.size() > 0);
		System.Assert(controller.listSOLookupAuctionItems.size() > 0);
		System.Assert(controller.campaignIdAuctionAttendees == campaign.Id);
	
		list<AUC_PurchaseOpportunity> listAPO = controller.getAuctionPurchasedItems();
		listAPO[0].strBidderNumberAndName = '123: Johnny Test';
		listAPO[0].contactId = contact.Id;
		listAPO[0].strAuctionItemIDAndName = strAIName + ': ' + auctionitem.Auction_Item_Name__c;
		listAPO[0].opp.Auction_Item_Purchased__c = auctionitem.Id;
		listAPO[0].strAmount = '99';
		listAPO[0].IsPayNow = false;
		listAPO[0].opp.CloseDate = date.valueof('2049-12-31');
		//listAPO[1].strBidderNumberAndName = '456: invalid number';
		//listAPO[1].strAuctionItemIDAndName = 'not there';
		
		//controller.LoadBidder();
		//controller.LoadAuctionItem();
		system.AssertEquals('Johnny Test', listAPO[0].strBidderName);
		system.AssertEquals('Test Auction item', listAPO[0].strAuctionItemName);
		//system.AssertEquals('invalid number', listAPO[1].strBidderName);
		//system.AssertEquals('not there', listAPO[1].strAuctionItemName);
		
		// do the save and validate it works
		//listAPO[1].strBidderNumberAndName = null;
		//listAPO[1].strAuctionItemIDAndName = null;
		controller.CreateAuctionPurchases();
		System.AssertEquals('Successfully saved 1 auction purchase(s).', controller.strSaveResults);
		list<Opportunity> auctionpurchases = [select Amount, Auction_Item_Name__c from Opportunity where CloseDate=:date.valueof('2049-12-31')];
		system.Assert(auctionpurchases.size() > 0);
		system.AssertEquals(99, auctionpurchases[0].Amount);
		system.AssertEquals('Test Auction item', auctionpurchases[0].Auction_Item_Name__c); 
		
		list<OpportunityContactRole> listOCR = [select Id, ContactId from OpportunityContactRole where isPrimary=true];
		system.assertEquals(1,listOCR.size());
		system.assertEquals(contact.Id, listOCR[0].ContactId);
		
		controller.Cancel();  
		
		
		// test handling no auction
		controller.auctionId = auction.id;
		controller.ChangeAuction();
		System.Assert(controller.listSOLookupBidNumbers.size() > 0);
		System.Assert(controller.listSOLookupAuctionItems.size() > 0);
		System.Assert(controller.campaignIdAuctionAttendees == campaign.Id);    
    }

    static testMethod void UnitTestNullAuction() {
    	// delete all auctions first
    	delete [select Id from Auction__c];
        	
    	//point to our VF page
    	PageReference page = new PageReference('Page.NewAuctionPurchaseWizard');
    	page.getParameters().put('auctionId', 'null');
		Test.setCurrentPageReference(page);
		
		//instantiate the controller for this opp
		AUC_CTRL_AuctionNewPurchaseWizard ctrl = new AUC_CTRL_AuctionNewPurchaseWizard();
		System.AssertEquals(null, ctrl.auctionId);
		System.AssertEquals(null, ctrl.campaignIdAuctionAttendees);
		System.AssertEquals(1, ctrl.listSOAuctions.size());		
		ctrl.Cancel();  
    }
        
}