// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
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
			list<RecordType> listRT = [SELECT Id FROM RecordType WHERE DeveloperName=:AUC_AuctionConstants.RECORDTYPE_OPP_AuctionGift];
			if (listRT.size() == 0) return recordtypeIdAuctionPurchasedItem;
			recordtypeIdAuctionGift = listRT[0].Id;
			return recordtypeIdAuctionGift;
		}		
		set;
	}	
	
	// the list of Auctions to put in the Auction dropdown
	public list<SelectOption> listSOAuctions {
		get {
			list<SelectOption> listSO = new list<SelectOption>();
			listSO.add(new SelectOption('', ''));
			for (Auction__c a : [select name, id from Auction__c order by Auction_Date__c desc limit 500]) {
				listSO.add(new SelectOption(a.id, a.name));
			}		
			return listSO;
		}
	}
	
	// the Auction Attendee Campaign for the selected Auction
	public Id campaignIdAuctionAttendees {
		get {
			if (campaignIdAuctionAttendees == null && auctionId != null) {
				list<Campaign> listCampaign= [select Id from Campaign 
					where (Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees or 
							Type=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees) 
						and Auction__c != null 
						and Auction__c= :auctionId limit 1];
				if (listCampaign.size() > 0) {
					campaignIdAuctionAttendees = listCampaign[0].Id;
				} else {
					throw (new MyException('The auction is missing its required Auction Attendees campaign.'));
				}
			}		
			return campaignIdAuctionAttendees;
		}
		
		set;
	}	

	// the Auction Donor Campaign for the selected Auction
	public Id campaignIdAuctionDonors {
		get {
			if (campaignIdAuctionDonors == null && auctionId != null) {
				list<Campaign> listCampaign= [select Id from Campaign 
					where (Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors or
							Type=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors)
						and Auction__c != null 
						and Auction__c= :auctionId limit 1];
				if (listCampaign.size() > 0) {
					campaignIdAuctionDonors = listCampaign[0].Id;
				} else {
					throw (new MyException('The auction is missing its required Auction Item Donors campaign.'));
				}
			}		
			return campaignIdAuctionDonors;
		}
		
		set;
	}

	// the Auction Ticket Campaign for the selected Auction
	public Id campaignIdAuctionTickets {
		get {
			if (campaignIdAuctionTickets == null && auctionId != null) {
				list<Campaign> listCampaign= [select Id from Campaign 
					where (Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets or
							Type=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets)
						and Auction__c != null 
						and Auction__c= :auctionId limit 1];
				if (listCampaign.size() > 0) {
					campaignIdAuctionTickets = listCampaign[0].Id;
				} else {
					throw (new MyException('The auction is missing its required Auction Tickets campaign.'));
				}
			}		
			return campaignIdAuctionTickets;
		}
		
		set;
	}
	
	// helper function to return a name for Ticket opps.
	// used by both teh NewTicketWizard, and CheckIn.
	public string StrOppTicketName(Id accountId, Id contactId) {
		string strTicketOwner;
	   	if (accountId != null) {
	        Account acc = [select Id, Name from Account where Id = :accountId];
			strTicketOwner = acc.Name; 
	   	} else if (contactId != null) {
			Contact contact = [select Name, AccountId from Contact where Id=:contactId];
			strTicketOwner = contact.Name;
	   	}
	   	
		string strAuction = AUC_AuctionMaintenance.NameOfAuctionId(auctionId);
		// remove trailing word Auction if it's there, so we don't get "auction" auction ticket.
		if (strAuction != null && strAuction.endsWith(' Auction')) {
			strAuction = strAuction.substring(0, strAuction.length() - 8);
		}
	   	
	    return (strTicketOwner + ' ' + strAuction + AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket);	
	}

	
	public static Integer YearOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [select Auction_Date__c from Auction__c where Id=:auctionId];		
		return (auc.Auction_Date__c == null ? system.today().year() : auc.Auction_Date__c.year());
	}
	
	public static Date DateOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [select Auction_Date__c from Auction__c where Id=:auctionId];
		return (auc.Auction_Date__c == null ? system.today() : auc.Auction_Date__c);
	}
		
	public static String NameOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [select Name from Auction__c where Id=:auctionId];
		return auc.Name;
	}
	
	public static Decimal TicketNonDeductibleAmountOfAuctionId(Id auctionId) {
		if (auctionId == null) return null;
		Auction__c auc = [select Ticket_Non_Deductible_Amount__c from Auction__c where Id=:auctionId];
		return (auc.Ticket_Non_Deductible_Amount__c == null) ? 0 : 	auc.Ticket_Non_Deductible_Amount__c;	
	}
		
	// public utility to escape a string.
	public static string StrEscape(string str) {
		if (str == null) return null;
		return string.escapeSingleQuotes(str);
	}
		
	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today(),
			Ticket_Non_Deductible_Amount__c = 25
		);  
		insert auction;  	
    	   	
		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
		am.AuctionId = auction.Id;
		
		System.Assert(AUC_AuctionMaintenance.recordtypeIdAuctionCampaign != null);
		System.Assert(AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem != null);
		System.Assert(AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem != null);
		System.Assert(AUC_AuctionMaintenance.recordtypeIdAuctionTicket != null);
		System.Assert(AUC_AuctionMaintenance.recordtypeIdAuctionGift != null);
		System.AssertEquals(system.today().year(), AUC_AuctionMaintenance.YearOfAuctionId(auction.Id));
		System.AssertEquals(system.today(), AUC_AuctionMaintenance.DateOfAuctionId(auction.Id));
		System.AssertEquals('Test Auction', AUC_AuctionMaintenance.NameOfAuctionId(auction.Id));
		
		list<SelectOption> listSO = am.listSOAuctions;
		System.Assert(listSO.size() > 1);
		
		System.Assert(am.campaignIdAuctionAttendees != null);
		System.Assert(am.campaignIdAuctionDonors != null);
		System.Assert(am.campaignIdAuctionTickets != null);	
		System.AssertEquals(25, AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auction.Id));
	}	
}