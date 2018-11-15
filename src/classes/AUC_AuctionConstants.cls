// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_AuctionConstants { 

	// Various RecordTypes
	public static final String RECORDTYPE_CAMPAIGN_Auction = 'GW_Auction_Campaign';
	public static final String RECORDTYPE_OPP_AuctionDonatedItem = 'GW_Auction_Donated_Item';
	public static final String RECORDTYPE_OPP_AuctionPurchasedItem = 'GW_Auction_Purchased_Item';
	public static final String RECORDTYPE_OPP_AuctionTicket = 'GW_Auction_Ticket';
	public static final String RECORDTYPE_OPP_AuctionAttendee = 'GW_Auction_Attendee';

	// The four Types of Campaigns automatically created for each Auction
	public static final String CAMPAIGN_TYPE_AuctionAttendees = 'Auction Attendees';
	public static final String CAMPAIGN_TYPE_AuctionTickets = 'Auction Tickets';
	public static final String CAMPAIGN_TYPE_AuctionSponsors = 'Auction Sponsors';
	public static final String CAMPAIGN_TYPE_AuctionItemDonors = 'Auction Item Donors';

	// The Suffixes used for the Campaign Names created for Auctions.
	public static final String CAMPAIGN_NAME_SUFFIX_AuctionAttendees = ' Attendees';
	public static final String CAMPAIGN_NAME_SUFFIX_AuctionTickets = ' Tickets';
	public static final String CAMPAIGN_NAME_SUFFIX_AuctionSponsors = ' Sponsors';
	public static final String CAMPAIGN_NAME_SUFFIX_AuctionItemDonors = ' Item Donors';

	// The Suffixes used for the Opportunity Names created for Items, Tickets, etc.
	public static final String OPP_NAME_SUFFIX_AuctionDonatedItem = ' Auction Donated Item';
	public static final String OPP_NAME_SUFFIX_AuctionTicket = ' Auction Ticket';
	public static final String OPP_NAME_SUFFIX_AuctionPurchasedItem  = ' Auction Purchased Item';
	public static final String OPP_NAME_SUFFIX_AuctionGift  = ' Auction Gift';

	private class MyException extends Exception {}

	// the Opportunity Record Type to use for gifts/donations.
	public static String RECORDTYPE_OPP_AuctionGift {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Opportunity_Record_Type_Gift__c == null) {
				return AUC_AuctionConstants.RECORDTYPE_OPP_AuctionPurchasedItem;
			}
			return settings[0].Opportunity_Record_Type_Gift__c;
		}
	}

	// Opportunity Contact Roles that will be used for tickets, donated items, purchases, etc.
	public static String OPP_GIFT_DONOR_ROLE {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Opportunity_Gift_Donor_Role__c == null) {
				return 'Individual Donor';
			}
			return settings[0].Opportunity_Gift_Donor_Role__c;
		}
	}

	public static String OPP_ORG_GIFT_DONOR_ROLE {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Opportunity_Gift_Org_Donor_Role__c == null) {
				return 'Organizational Donor';
			}
			return settings[0].Opportunity_Gift_Org_Donor_Role__c;
		}
	}

	// The Opportunity Stage to set for new auction item purchases.
	public static String OPP_STAGE_WON_NOT_THANKED_STAGE {
		get {
			if (OPP_STAGE_WON_NOT_THANKED_STAGE == null) {
				String strStage = 'Closed Won';
				List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
				if (settings.size() > 0 && settings[0].Opportunity_Stage_Won_Not_Thanked__c != null) {
					strStage = settings[0].Opportunity_Stage_Won_Not_Thanked__c;
				}
				// verify it is a valid stage and retrieve Probability and ForecastCategory for later use
				List<OpportunityStage> ListSt = [SELECT MasterLabel, DefaultProbability, ForecastCategoryName, IsWon, IsClosed, IsActive
					FROM OpportunityStage
					WHERE MasterLabel = :strStage AND IsWon = TRUE AND IsClosed = TRUE AND IsActive = TRUE];
				if (ListSt.size() == 0) {
					throw (new MyException('The Auction Setting for Opportunity Stage Won Not Thanked, '
						+ strStage + ', is not a valid Won, Closed, and Active Opportunity Stage.  Please see the Auctions Installation & Configuration Guide.'));
				}
				oppStageWonNotThankedProbability = ListSt[0].DefaultProbability;
				oppStageWonNotThankedForecastCategoryName = ListSt[0].ForecastCategoryName;
				OPP_STAGE_WON_NOT_THANKED_STAGE = strStage;
			}
			return OPP_STAGE_WON_NOT_THANKED_STAGE;
		}
		private set;
	}

	public static Double oppStageWonNotThankedProbability { get; private set; }
	public static String oppStageWonNotThankedForecastCategoryName { get; private set; }

	public static String OPP_STAGE_PLEDGED {
		get {
			if (OPP_STAGE_PLEDGED == null) {
				String strStage = 'Pledged';
				List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
				if (settings.size() > 0 && settings[0].Opportunity_Stage_Pledged__c != null) {
					strStage = settings[0].Opportunity_Stage_Pledged__c;
				}
				// verify it is a valid stage
				List<OpportunityStage> ListSt = [SELECT MasterLabel, IsWon, IsClosed, IsActive FROM OpportunityStage
					WHERE MasterLabel = :strStage AND IsActive = TRUE];
				if (ListSt.size() == 0) {
					throw (new MyException('The Auction Setting for Opportunity Stage Pledged, '
						+ strStage + ', is not a valid Active Opportunity Stage.  Please see the Auctions Installation & Configuration Guide.'));
				}
				OPP_STAGE_PLEDGED = strStage;
			}
			return OPP_STAGE_PLEDGED;
		}
		private set;
	}

	// The default Status to set for the Auction's auto-created Campaigns.
	public static String CAMPAIGN_Status_Default {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Campaign_Status_Default__c == null) {
				return 'In Progress';
			}
			return settings[0].Campaign_Status_Default__c;
		}
	}

	// how many rows to show in the Auction Ticket Purchases grid
	public static Integer CROWS_PURCHASE_GRID {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Number_of_Purchase_Grid_Rows__c == null) {
				return 15;
			}
			Double db = settings[0].Number_of_Purchase_Grid_Rows__c;
			return db.intValue();
		}
	}

	// how many records to show per page on Auction Tabs
	public static Integer cRecordsPerPage {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Number_of_Records_Per_Page__c == null) {
				return 25;
			}
			Double db = settings[0].Number_of_Records_Per_Page__c;
			if (db == 0) {
				return 25;
			}
			return db.intValue();
		}
	}

	// whether to allow duplicate Bid Numbers per Auction, or not.
	public static Boolean fAllowDuplicateBidNumbers {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Allow_Duplicate_Bid_Numbers__c == null) {
				return false;
			}
			return settings[0].Allow_Duplicate_Bid_Numbers__c;
		}
	}

	// Get the user's Auction Receipts Intro text.
	public static String StrAuctionReceiptsIntro() {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() > 0) {
				String str;
				if (settings[0].Auction_Receipts_Intro_1__c != null) str = settings[0].Auction_Receipts_Intro_1__c;
				if (settings[0].Auction_Receipts_Intro_2__c != null) str = str + ' ' + settings[0].Auction_Receipts_Intro_2__c;
				if (str != null) return str;
			}
			return 'Please see the Auctions for Salesforce User\'s Guide to see how to set the Introductory text for Auction Receipts.';
	}

	// Get the user's Auction Receipts Footer text.
	public static String StrAuctionReceiptsFooter() {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() > 0) {
				String str;
				if (settings[0].Auction_Receipts_Footer_1__c != null) str = settings[0].Auction_Receipts_Footer_1__c;
				if (settings[0].Auction_Receipts_Footer_2__c != null) str = str + ' ' + settings[0].Auction_Receipts_Footer_2__c;
				if (str != null) return str;
			}
			return 'Please see the Auctions for Salesforce User\'s Guide to see how to set the Footer text for Auction Receipts.';
	}

	// read the custom setting and return the String for the Credit Card Validate URL formula for the CheckIn page.
	public static String StrCreditCardValidateURLFormula() {
		List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
		if (settings.size() > 0) {
			return settings[0].CreditCardValidateURLFormula__c;
		} else {
			return null;
		}
	}

	// read the custom setting and return the String for the Credit Card Charge URL formula for the CheckOut page.
	public static String StrCreditCardChargeURLFormula() {
		List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
		if (settings.size() > 0) {
			return settings[0].CreditCardChargeURLFormula__c;
		} else {
			return null;
		}
	}

	// read the custom setting and return the String for the window.open() parameters
	// when opening the Payment Processor Virtual Terminal.
	public static String StrPaymentProcessorWindowParameters() {
		List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
		if (settings.size() > 0) {
			return settings[0].Payment_Processor_Window_Parameters__c;
		} else {
			return 'menubar=0,status=0,toolbar=0,width=700,height=600';
		}
	}

	// read the custom setting and return the String for the iframe height
	// when opening the Payment Processor Virtual Terminal on our Auction pages.
	public static String StrPaymentProcessorPageHeight() {
		List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
		if (settings.size() > 0) {
			return settings[0].Payment_Processor_Page_Height__c;
		} else {
			return '300px';
		}
	}

	// whether to display the payment processor's virtual terminal on our page, or in a new browser window.
	public static Boolean fShowPaymentProcessorOnPage {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Show_Payment_Processor_On_Page__c == null) {
				return false;
			}
			return settings[0].Show_Payment_Processor_On_Page__c;
		}
	}

	// the developer field name of an optional Opportunity Payment Method field
	// that Check Out will save into.
	public static String strOppPaymentMethodField {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0) {
				return null;
			}
			return settings[0].Opportunity_Payment_Method_Field__c;
		}
	}

	// the developer field name of an optional Opportunity Check Number field
	// that Check Out will save into.
	public static String strOppCheckNumberField {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0) {
				return null;
			}
			return settings[0].Opportunity_Check_Number_Field__c;
		}
	}

	// whether to set the Account field on new opportunities
	public static Boolean fSetAccountOnNewAuctionOpps {
		get {
			Boolean fSetAccount = false;
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() > 0) {
				fSetAccount = settings[0].Set_Account_On_New_Opportunities__c;
			}

			// even if the setting is off, still do this for NPSP 1:1 and HH Account model
			return (fSetAccount || isNPSPOneToOneAccountModel || isNPSPHouseholdAccountModel);
		}
	}

	// developer name of a lookup field on Contact that points to Households
	public static String strContactHouseholdField {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() > 0) {
				strContactHouseholdField = settings[0].Contact_Household_Field__c;
			}
			if (strContactHouseholdField == null && useNPSPHouseholdObject) {
				strContactHouseholdField = 'npo02__Household__c';
			} else if (strContactHouseholdField == null && isNPSPHouseholdAccountModel) {
				strContactHouseholdField = 'AccountId';
			}
			return strContactHouseholdField;
		}
		set;
	}

	// the developer path to the Name field on Households from Contact
	public static String strContactHouseholdNameField {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() > 0) {
				strContactHouseholdNameField = settings[0].Contact_Household_Name_Field__c;
			}
			if (strContactHouseholdNameField == null && useNPSPHouseholdObject) {
				strContactHouseholdNameField = 'npo02__Household__r.Name';
			} else if (strContactHouseholdNameField == null && isNPSPHouseholdAccountModel) {
				strContactHouseholdNameField = 'Account.Name';
			}
			return strContactHouseholdNameField;
		}
		set;
	}

	// the developer path to the Greeting field on Households from Contact
	public static String strContactHouseholdGreetingField {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() > 0) {
				strContactHouseholdGreetingField = settings[0].Contact_Household_Greeting_Field__c;
			}
			if (strContactHouseholdGreetingField == null && useNPSPHouseholdObject) {
				strContactHouseholdGreetingField = 'npo02__Household__r.npo02__Informal_Greeting__c';
			} else if (strContactHouseholdGreetingField == null && isNPSPHouseholdAccountModel) {
				strContactHouseholdGreetingField = 'Account.npo02__Informal_Greeting__c';
			}
			return strContactHouseholdGreetingField;
		}
		set;
	}

	// maximum number of new Auction Item rows to show in the Donated Item Converter.
	public static Integer cDonatedItemConverterBatchSize {
		get {
			List<AuctionSettings__c> settings = AuctionSettings__c.getAll().values();
			if (settings.size() == 0 || settings[0].Donated_Item_Converter_Batch_Size__c == null) {
				return 25;
			}
			Double db = settings[0].Donated_Item_Converter_Batch_Size__c;
			if (db == 0) {
				return 25;
			}
			return db.intValue();
		}
	}


	//From the Non Profit Starter Pack.
	//Account Model values
	@TestVisible private static String ONE_TO_ONE_PROCESSOR = 'One-to-One';
	@TestVisible private static String BUCKET_PROCESSOR = 'Individual';
	@TestVisible private static String HH_ACCOUNT_PROCESSOR = 'Household Account';

	//From the Non Profit Starter Pack.
	//method to tell which Account Model we're currently in for Accounts
	private static Boolean fCheckedNPSPAccountModel = false;
	@TestVisible private static String strNPSPAccountModel {
		get {
			if (!fCheckedNPSPAccountModel) {
				strNPSPAccountModel = null;
				if (IsNPSPInstalled) {
					String strSoql = 'SELECT Id, Name, npe01__Account_Processor__c FROM npe01__Contacts_And_Orgs_Settings__c';
					List<SObject> ListSObj = Database.query(strSoql);
					if (ListSObj != null && ListSObj.size() > 0) {
						strNPSPAccountModel = String.valueOf(ListSObj[0].get('npe01__Account_Processor__c'));
					}
				}
			fCheckedNPSPAccountModel = true;
			}
			return strNPSPAccountModel;
		}
		set;
	}

	//method to tell whether NPSP Payments are enabled
	private static Boolean fCheckedNPSPPayments = false;
	@TestVisible private static Boolean isNPSPPaymentsEnabled {
		get {
			if (!fCheckedNPSPPayments) {
				isNPSPPaymentsEnabled = false;
				if (IsNPSPInstalled) {
					String strSoql = 'SELECT Id, Name, npe01__Payments_Enabled__c FROM npe01__Contacts_And_Orgs_Settings__c';
					List<SObject> ListSObj = Database.query(strSoql);
					if (ListSObj != null && ListSObj.size() > 0) {
						isNPSPPaymentsEnabled = Boolean.valueOf(ListSObj[0].get('npe01__Payments_Enabled__c'));
					}
				}
			fCheckedNPSPPayments = true;
			}
			return isNPSPPaymentsEnabled;
		}
		set;
	}

	// property to tell whether there is no place to store the Payment Method (for NewTicketWizard and CheckOut pages)
	public static Boolean isPaymentSettingsMissing {
		get {
			return
				AUC_AuctionConstants.strOppPaymentMethodField == null &&
				AUC_AuctionConstants.strOppCheckNumberField == null &&
				AUC_AuctionConstants.isNPSPPaymentsEnabled == false;
		}
	}

	public static Boolean isNPSPOneToOneAccountModel {
		get {
			isNPSPOneToOneAccountModel = (strNPSPAccountModel == ONE_TO_ONE_PROCESSOR);
			return isNPSPOneToOneAccountModel;
		}
		set;
	}

	public static Boolean isNPSPHouseholdAccountModel {
		get {
			isNPSPHouseholdAccountModel = (strNPSPAccountModel == HH_ACCOUNT_PROCESSOR);
			return isNPSPHouseholdAccountModel;
		}
		set;
	}

	// public property to tell Auctions whether NPSP package is installed.
	private static Boolean fCheckedForNPSP = false;
	public static Boolean IsNPSPInstalled {
		get {
			if (!fCheckedForNPSP) {
				Schema.SObjectType token = Schema.getGlobalDescribe().get('npe01__Contacts_And_Orgs_Settings__c');
				IsNPSPInstalled = (token != null);
				fCheckedForNPSP = true;
			}
			return IsNPSPInstalled;
		}
		set;
	}

	// private property to tell Auctions whether NPSP Householding package is installed and Household Object to be used.
	private static Boolean fCheckedForNPSPHH = false;
	@TestVisible private static Boolean useNPSPHouseholdObject {
		get {
			if (!fCheckedForNPSPHH) {
				Schema.SObjectType token = Schema.getGlobalDescribe().get('npo02__Household__c');
				useNPSPHouseholdObject = (token != null) && !isNPSPHouseholdAccountModel;
				fCheckedForNPSPHH = true;
			}
			return useNPSPHouseholdObject;
		}
		set;
	}

	// method accepts the ID of any object type and returns the full name, including prefix of the sObject
	//type to which it belongs.
	public static Schema.SObjectType getObjectTypeFromId(Id sobjId) {

		if (sobjId == null) {
			return null;
		}
		String id = sobjId;

		// optimize hack!
		// we know the Salesforce standard prefixes!
		if (id.startsWith('003')) {
			return Contact.SObjectType;
		}
		if (id.startsWith('001')) {
			return Account.SObjectType;
		}

		// for others, we'll do the work!
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		String keyPrefix;

		for (Schema.SObjectType describe : gd.values()) {
			keyPrefix = describe.getDescribe().getKeyPrefix();
			if (keyPrefix != null && id.startsWith(keyPrefix)) {
				return describe;
			}
		}
		return null;
	}


}