// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_AuctionMaintenance {
	
	// constructor
	public AUC_AuctionMaintenance() {}
	
	public Id auctionId { 
		get; 
		set {
			auctionId = value;
			campaignIdAuctionAttendees = null; 
			campaignIdAuctionDonors = null;
			campaignIdAuctionTickets = null;
		}
	}
	
	private class MyException extends Exception {}

    public static Id recordtypeIdAuctionCampaign = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_CAMPAIGN_Auction].Id;
    public static Id recordtypeIdAuctionDonatedItem = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_OPP_AuctionDonatedItem].Id;
    public static Id recordtypeIdAuctionPurchasedItem = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_OPP_AuctionPurchasedItem].Id;
    public static Id recordtypeIdAuctionTicket = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_OPP_AuctionTicket].Id;
    public static Id recordtypeIdCampaignMemberAuctionAttendee = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_OPP_AuctionAttendee].Id;

	// don't assume the Gift record type exists, since we want to use the client's gift or donation record type,
	// but on installation, the client won't have been able to set the custom setting telling us what it is!
	// so just make the soql robust to avoid install errors.
	public static Id recordtypeIdAuctionGift { 
		get {
			if (recordtypeIdAuctionGift <> null) return recordtypeIdAuctionGift;
			List<RecordType> listRT = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_OPP_AuctionGift];
			if (listRT.size() == 0) return recordtypeIdAuctionPurchasedItem;
			recordtypeIdAuctionGift = listRT[0].Id;
			return recordtypeIdAuctionGift;
		}		
		set;
	}	
	
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions {
		get {
			List<SelectOption> listSO = new List<SelectOption>();
			listSO.add(new SelectOption('', ''));
			for (Auction__c a : [SELECT Name, Id FROM Auction__c ORDER BY Auction_Date__c DESC LIMIT 500]) {
				listSO.add(new SelectOption(a.Id, a.Name));
			}		
			return listSO;
		}
	}
	
	// the Auction Attendee Campaign for the selected Auction
	public Id campaignIdAuctionAttendees {
		get {
			if (campaignIdAuctionAttendees == null && auctionId != null) {
				List<Campaign> listCampaign= [SELECT Id FROM Campaign 
					WHERE (Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees OR 
							Type=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees) 
						AND Auction__c != NULL 
						AND Auction__c= :auctionId LIMIT 1];
				if (listCampaign.size() > 0) {
					campaignIdAuctionAttendees = listCampaign[0].Id;
				} else {
					throw (new MyException('The auction is missing its required Auction Attendees campaign.'));
				}
			}		
			return campaignIdAuctionAttendees;
		}
		
		private set;
	}	

	// the Auction Donor Campaign for the selected Auction
	public Id campaignIdAuctionDonors {
		get {
			if (campaignIdAuctionDonors == null && auctionId != null) {
				List<Campaign> listCampaign= [SELECT Id FROM Campaign 
					WHERE (Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors OR
							Type=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors)
						AND Auction__c != NULL 
						AND Auction__c= :auctionId LIMIT 1];
				if (listCampaign.size() > 0) {
					campaignIdAuctionDonors = listCampaign[0].Id;
				} else {
					throw (new MyException('The auction is missing its required Auction Item Donors campaign.'));
				}
			}		
			return campaignIdAuctionDonors;
		}
		
		private set;
	}

	// the Auction Ticket Campaign for the selected Auction
	public Id campaignIdAuctionTickets {
		get {
			if (campaignIdAuctionTickets == null && auctionId != null) {
				List<Campaign> listCampaign= [SELECT Id FROM Campaign 
					WHERE (Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets OR
							Type=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets)
						AND Auction__c != NULL 
						AND Auction__c= :auctionId LIMIT 1];
				if (listCampaign.size() > 0) {
					campaignIdAuctionTickets = listCampaign[0].Id;
				} else {
					throw (new MyException('The auction is missing its required Auction Tickets campaign.'));
				}
			}		
			return campaignIdAuctionTickets;
		}
		
		private set;
	}
	
	// helper function to return a name for Ticket opps.
	// used by both teh NewTicketWizard, and CheckIn.
	public String StrOppTicketName(Id accountId, Id contactId) {
		String strTicketOwner;
	    if (contactId != null) {
			Contact contact = [SELECT Name, AccountId FROM Contact WHERE Id=:contactId];
			strTicketOwner = contact.Name;
	   	} else if (accountId != null) {
	        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId];
			strTicketOwner = acc.Name; 
	    }
		String strAuction = AUC_AuctionMaintenance.NameOfAuctionId(auctionId);
		// remove trailing word Auction if it's there, so we don't get "auction" auction ticket.
		if (strAuction != null && strAuction.endsWith(' Auction')) {
			strAuction = strAuction.substring(0, strAuction.length() - 8);
		}
	   	
	    return (strTicketOwner + ' ' + strAuction + AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket);	
	}

	
	public static Integer YearOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [SELECT Auction_Date__c FROM Auction__c WHERE Id=:auctionId];		
		return (auc.Auction_Date__c == null ? System.today().year() : auc.Auction_Date__c.year());
	}
	
	public static Date DateOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [SELECT Auction_Date__c FROM Auction__c WHERE Id=:auctionId];
		return (auc.Auction_Date__c == null ? System.today() : auc.Auction_Date__c);
	}
		
	public static String NameOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [SELECT Name FROM Auction__c WHERE Id=:auctionId];
		return auc.Name;
	}
	
	public static Decimal TicketNonDeductibleAmountOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [SELECT Ticket_Non_Deductible_Amount__c FROM Auction__c WHERE Id=:auctionId];
		return (auc.Ticket_Non_Deductible_Amount__c == null) ? 0 : 	auc.Ticket_Non_Deductible_Amount__c;	
	}
		
	// public utility to escape a String.
	public static String StrEscape(String str) {
		if (str == null) return null;
		return String.escapeSingleQuotes(str);
	}
	
	// utility to return a list of Strings from a field set.
	public static List<String> listStrFromFieldSet(String strObject, String strFS) {
		List<String> listStrFields = new List<String>();
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(strObject);
		Schema.DescribeSObjectResult d = targetType.getDescribe(); 
		Schema.FieldSet fs = d.fieldSets.getMap().get(strFS);
		
		// to protect against the fieldset not existing.
		// found a case of this where the user had their own object called Auction_Item__c
		// which didn't have our field set and we would dereference fs and hit an error.
		if (fs == null) {
			return listStrFields;
		}

		for(Schema.FieldSetMember f : fs.getFields()) {
			if (f.getFieldPath().contains('.')) {
				throw (new MyException('Auctions does not support related field \'' + f.getFieldPath() + 
					'\' in field set \'' + strFS + '\'.  You can only include fields directly on object \'' + strObject + '\'.'));
			}
            listStrFields.add(f.getFieldPath());
        }
		return listStrFields;
	}
	
	// utility to return a comma separated String of field names from a field set
	public static String strFieldNamesFromFieldSet(String strObject, String strFS) {
		String strFields = '';
		for (String str : listStrFromFieldSet(strObject, strFS)) {
			strFields += str + ',';
		}
		if (strFields == '') {
			return '';
		}
		return strFields.substring(0, strFields.length()-1);		
	}
		
	// utility to copy all the field values from one SObject to another
	public static void CloneObject (SObject sobjSrc, SObject sobjDst, List<String> listStrFields) {
        for (String strF : listStrFields) {
         	if (sobjSrc.get(strF) != null) { 
          		try {
           			sobjDst.put(strF, sobjSrc.get(strF));
           		} catch(Exception ex) { 
					// exceptions will be thrown on readonly fields
					// so we want to continue, not fail.            			
           		}
           	}
        }
	}
	
	// utility to check if using NPSP Payments, and update payment info for the list of Opps.
	public static void UpdateNPSPPayments(List<Opportunity> listOppToUpdate, String strPaymentMethod, String strCheckNumber) {
		if (AUC_AuctionConstants.IsNPSPInstalled) {
			try {
				List<SObject> listPayments = new List<SObject>();
				String strSoql = 'select Id, npe01__Payment_Method__c, npe01__Check_Reference_Number__c  ' +
					' from npe01__OppPayment__c where npe01__Opportunity__c in :listOppToUpdate ';
				listPayments = Database.query(strSoql);
				if (listPayments.size() > 0) {
					for (SObject payment : listPayments) {
						payment.put('npe01__Payment_Method__c', strPaymentMethod);
						if (strPaymentMethod == 'Check') {
							payment.put('npe01__Check_Reference_Number__c', strCheckNumber);
						}
					}
					update listPayments;
				}
			} catch (Exception e) {
				// no cleanup needed.
			}
		}
	}
	
	// returns the Payment Method or Check Number for the specified OppId, if that Opp has NPSP Payments.
	private static List<SObject> listPayments;
	public static String strPaymentMethodOrCheckFromNPSPPayments(Id oppId, Boolean isCheck) {
		if (AUC_AuctionConstants.IsNPSPInstalled) {
			if (listPayments == null || listPayments.size() == 0 || listPayments[0].get('npe01__Opportunity__c') != oppId) {
				String strSoql = 'select Id, npe01__Payment_Method__c, npe01__Check_Reference_Number__c, npe01__Opportunity__c  ' +
					' from npe01__OppPayment__c where npe01__Opportunity__c = :oppId ';
				listPayments = Database.query(strSoql);
			}
			if (listPayments.size() > 0) {
				for (SObject payment : listPayments) {
					String strVal = String.valueOf(payment.get(isCheck ? 'npe01__Check_Reference_Number__c' : 'npe01__Payment_Method__c'));
					if (strVal != null) {
						return strVal;
					}
				}
			}
		}
		return null;
	}
	
	// for NPSP installations, set the appropriate field on the Opportunity
	// to create the correct OCR for the contact.  We previously did this after
	// the opp was saved, but changes in NPSP 3.0 cause NPSP to create a primary OCR
	// for the account's primary contact, if the special OCR fields are not filled in.
	// note that even though this returns true if it set the field, i found that this
	// wasn't enough in NPSP 2.0, and so recommend the Auctions' code still look for
	// the OCR's after the opp insert.
	public static Boolean didUpdateOppWithNPSPOCRData(Opportunity opp, Id contactId) {
		try {
			if (!AUC_AuctionConstants.IsNPSPInstalled) {
				return false;
			}
			if (AUC_AuctionConstants.isNPSPHouseholdAccountModel) {	// cheap way to detect 3.0
				opp.put('npsp__Primary_Contact__c', contactId);
			} else {
				opp.put('npe01__Contact_Id_for_Role__c', contactId); // assume npsp 2.0 field (though didn't seem to work!)
			}
			return true;
		} catch (Exception ex) {
			return false;
		}		
	}

	// because NPSP may have already created contact roles, depending on account model, and whether a given contact
	// has a 1:1 account or a company account, we will check each Opp, to see if it needs a contact role or not,
	// as well as ensure its Role is correct.
	public static void saveOppContactRole(OpportunityContactRole ocr) {
		saveOppContactRoles(new List<OpportunityContactRole> {ocr});
	}

	public static void saveOppContactRoles(List<OpportunityContactRole> listOCR) {
		if (listOCR.size() > 0) {
			List<OpportunityContactRole> listOCRUpsert = new List<OpportunityContactRole>();

			Set<Id> setOppId = new Set<Id>();
			for (OpportunityContactRole ocr : listOCR) {
				setOppId.add(ocr.OpportunityId);
			}
			List<OpportunityContactRole> listOCRExisting = [SELECT Id, Role, ContactId, OpportunityId
				FROM OpportunityContactRole WHERE IsPrimary = TRUE AND OpportunityId IN :setOppId];

			// put all our OCR's on a map key'ed by OppId|ContactId
			Map<String, OpportunityContactRole> mapKeyToOCR = new Map<String, OpportunityContactRole>();
			for (OpportunityContactRole ocr : listOCRExisting) {
				mapKeyToOCR.put(ocr.OpportunityId + '|' + ocr.ContactId, ocr);
			}

			// now fixup the Roles in the ocr's
			for (Integer i = 0; i < listOCR.size(); i++) {
				OpportunityContactRole ocr = listOCR[i];
				OpportunityContactRole ocrExisting = mapKeyToOCR.get(ocr.OpportunityId + '|' + ocr.ContactId);
				if (ocrExisting != null) {
					if (ocrExisting.Role != ocr.Role) {
						ocrExisting.Role = ocr.Role;
						listOCRUpsert.add(ocrExisting);
					}
				} else {
					listOCRUpsert.add(ocr);
				}
			}

			upsert listOCRUpsert;
		}
	}

	// Sets the Opportunity StageName, Probability, and ForecastCategoryName to the Closed Won Not Thanked
	// stage specified in Settings.
	public static void setOpportunityStageClosed(Opportunity opp) {
		opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;
		opp.Probability = AUC_AuctionConstants.oppStageWonNotThankedProbability;
		opp.ForecastCategoryName = AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName;
	}
		
}