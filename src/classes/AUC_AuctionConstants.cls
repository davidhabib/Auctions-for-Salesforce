// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_AuctionConstants { 
	
	// Various RecordTypes
	public static final string RECORDTYPE_CAMPAIGN_Auction = 'GW_Auction_Campaign';
	public static final string RECORDTYPE_OPP_AuctionDonatedItem = 'GW_Auction_Donated_Item';
	public static final string RECORDTYPE_OPP_AuctionPurchasedItem = 'GW_Auction_Purchased_Item';
	public static final string RECORDTYPE_OPP_AuctionTicket = 'GW_Auction_Ticket';
	public static final string RECORDTYPE_OPP_AuctionAttendee = 'GW_Auction_Attendee';

	// The four Types of Campaigns automatically created for each Auction
	public static final string CAMPAIGN_TYPE_AuctionAttendees = 'Auction Attendees';
	public static final string CAMPAIGN_TYPE_AuctionTickets = 'Auction Tickets';
	public static final string CAMPAIGN_TYPE_AuctionSponsors = 'Auction Sponsors';
	public static final string CAMPAIGN_TYPE_AuctionItemDonors = 'Auction Item Donors';
	
	// The Suffixes used for the Campaign Names created for Auctions.
	public static final string CAMPAIGN_NAME_SUFFIX_AuctionAttendees = ' Attendees';
	public static final string CAMPAIGN_NAME_SUFFIX_AuctionTickets = ' Tickets';
	public static final string CAMPAIGN_NAME_SUFFIX_AuctionSponsors = ' Sponsors';
	public static final string CAMPAIGN_NAME_SUFFIX_AuctionItemDonors = ' Item Donors';
	
	// The Suffixes used for the Opportunity Names created for Items, Tickets, etc.
	public static final string OPP_NAME_SUFFIX_AuctionDonatedItem = ' Auction Donated Item';
	public static final string OPP_NAME_SUFFIX_AuctionTicket = ' Auction Ticket';
	public static final string OPP_NAME_SUFFIX_AuctionPurchasedItem  = ' Auction Purchased Item';
	public static final string OPP_NAME_SUFFIX_AuctionGift  = ' Auction Gift';
	
	// the Opportunity Record Type to use for gifts/donations.
	public static string RECORDTYPE_OPP_AuctionGift { 
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return AUC_AuctionConstants.RECORDTYPE_OPP_AuctionPurchasedItem;
			return settings[0].Opportunity_Record_Type_Gift__c;
		}
	}

	// Opportunity Contact Roles that will be used for tickets, donated items, purchases, etc.
	public static string OPP_GIFT_DONOR_ROLE {
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return 'Individual Donor';
			return settings[0].Opportunity_Gift_Donor_Role__c;
		}
	}
	
	public static string OPP_ORG_GIFT_DONOR_ROLE {
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return 'Organizational Donor';
			return settings[0].Opportunity_Gift_Org_Donor_Role__c;
		}
	}
	
	// The Opportunity Stage to set for new auction item purchases.
	public static string OPP_STAGE_WON_NOT_THANKED_STAGE {
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return 'Closed Won - Not Thanked';
			return settings[0].Opportunity_Stage_Won_Not_Thanked__c;
		}
	}
	
	public static string OPP_STAGE_PLEDGED {
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return 'Pledged';
			return settings[0].Opportunity_Stage_Pledged__c;
		}
	}

	// The default Status to set for the Auction's auto-created Campaigns.
	public static string CAMPAIGN_Status_Default {
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return 'In Progress';
			return settings[0].Campaign_Status_Default__c;
		}
	}
		
	// how many rows to show in the Auction Ticket Purchases grid
	public static integer CROWS_PURCHASE_GRID {
		get {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() == 0) return 10;
			double db = settings[0].Number_of_Purchase_Grid_Rows__c;
			return db.intValue();
		}
	}

	// Get the user's Auction Receipts Intro text.
	public static string StrAuctionReceiptsIntro() {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() > 0) {
				string str;
				if (settings[0].Auction_Receipts_Intro_1__c != null) str = settings[0].Auction_Receipts_Intro_1__c;
				if (settings[0].Auction_Receipts_Intro_2__c != null) str = str + ' ' + settings[0].Auction_Receipts_Intro_2__c;
				if (str != null) return str;
			}				
			return 'Please see the Auctions for Salesforce User\'s Guide to see how to set the Introductory text for Auction Receipts.';
	} 

	// Get the user's Auction Receipts Footer text.
	public static string StrAuctionReceiptsFooter() {
			list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
			if (settings.size() > 0) {
				string str;
				if (settings[0].Auction_Receipts_Footer_1__c != null) str = settings[0].Auction_Receipts_Footer_1__c;
				if (settings[0].Auction_Receipts_Footer_2__c != null) str = str + ' ' + settings[0].Auction_Receipts_Footer_2__c;
				if (str != null) return str;
			}				
			return 'Please see the Auctions for Salesforce User\'s Guide to see how to set the Footer text for Auction Receipts.';
	} 
	
	// Get the user's list of Auction Donated Item Stages
	// if the setting exists, allow it to be null (to imply use values from Salesforce)
	// if the setting doesn't even exist, then return our default values.
	public static string StrDonatedItemOpportunityStages() {
		list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
		if (settings.size() > 0) {
			return settings[0].Donated_Item_Opportunity_Stages__c;
		} else {
			return 'Prospecting;Pledged;Closed Won;Closed Lost;Closed Won - Not Thanked';
		}
	}
	
	// Get the user's list of Auction Attendee CampaignMember Status values
	// if the setting exists, allow it to be null (to imply use values from Salesforce)
	// if the setting doesn't even exist, then return our default values.
	public static string StrAttendeeCampaignMemberStatuses() {
		list<AuctionSettings__c> settings = AuctionSettings__c.getall().values();
		if (settings.size() > 0) {
			return settings[0].Attendee_CampaignMember_Statuses__c;
		} else {
			return 'Invited;RSVP Yes;RSVP No;Donated';
		}
	}

	//From the Non Profit Starter Pack.
	//One-to-One value for system processor field 	
	private static String ONE_TO_ONE_PROCESSOR = 'One-to-One'; 

	//From the Non Profit Starter Pack.
	//method to tell which model we're currently in for Accounts     
    public static boolean isOneToOne() {     	
    	boolean isOneToOneModel;     	
    	isOneToOneModel = false;   
    	Map<String, Schema.SObjectField> M = Schema.SObjectType.Contact.fields.getMap();
    	Schema.SObjectField fld = M.get('npe01__SystemAccountProcessor__c');
    	if (fld == null) return false;  	
    	//Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.npe01__SystemAccountProcessor__c;
    	Schema.DescribeFieldResult F = fld.getDescribe();  
    	List<Schema.PicklistEntry> P = F.getPicklistValues(); 		
    	for(Schema.PicklistEntry pe : P){ 			
    		if (pe.isDefaultValue()){ 				
    			if(pe.getValue()==ONE_TO_ONE_PROCESSOR){ isOneToOneModel = true;} 			
    		} 		
    	} 		     	
    	return isOneToOneModel;     
    } 	
    
	// in order to avoid duplicate contact roles being created by us and the NPSP,
	// we have to be smart about when to do it.
	// In older versions of the NPSP (Households version < 2.0), one could prevent NPSP from 
	// creating contact roles on specific Opportunity record types.  Thus Auctions' installation guide instructs 
	// NPSP users to set each auction record type's _SYSTEM: HOUSEHOLD CONTACT ROLEPROCESSOR field to have a default value of "No Opportunities".  
	// Unfortunately, when NPSP moved to using custom settings to control its behavior, 
	// they only look at Household Settings - Household Contact Roles On, and they no longer support controlling this 
	// behavior by Opportunity record type.	
	//
	// According to Kevin Bromer on 3/8/2011:
	// In a 1x1 setup, the NPSP uses a before trigger on opps to populate the Contact_Id_for_Role__c from the associated 1x1 account. 
	// In a bucket account model, the NPSP relies on the baked in SFDC contact role creation (basically, only supporting URL param passing), 
	// then rolls through in an after-update to update role types if necessary.
	// 
	// Given this description, the fix is if Auctions detects 1:1 model, don't set a contact role, but set the account.  
	// If not a 1:1 model, go ahead and create the contact role.
    // public static boolean fCreateOppContactRoles() { 
	//    	return !isOneToOne();    	
    // }

    public static boolean fCreateOppContactRoles(ID oppId, ID contactId) {
    	if (oppId == null || contactId == null) return false;
    	OpportunityContactRole[] listOCR = [select Id from OpportunityContactRole where contactId=:contactId and OpportunityId=:oppId and IsPrimary=true]; 
    	return (listOCR.size() == 0);    	
    }
	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
		System.Assert(AUC_AuctionConstants.RECORDTYPE_OPP_AuctionGift != null);
		System.Assert(AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE != null);
		System.Assert(AUC_AuctionConstants.OPP_ORG_GIFT_DONOR_ROLE != null);
		System.Assert(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE != null);
		System.Assert(AUC_AuctionConstants.OPP_STAGE_PLEDGED != null);
		System.Assert(AUC_AuctionConstants.CAMPAIGN_Status_Default != null);
		System.Assert(AUC_AuctionConstants.CROWS_PURCHASE_GRID != null);
		System.Assert(AUC_AuctionConstants.isOneToOne() == false || AUC_AuctionConstants.isOneToOne() == true);
		System.Assert(AUC_AuctionConstants.StrAuctionReceiptsIntro() != null);
		System.Assert(AUC_AuctionConstants.StrAuctionReceiptsFooter() != null);
	}
	
	static testmethod void TestNoSettings() {		
		// now delete the custom settings, and make sure we are still robust.
        //clear out whatever settings exist
        delete [select id from AuctionSettings__c];
		CodeCoverageTests();
	}
}