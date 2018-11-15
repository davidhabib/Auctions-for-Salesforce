// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_AuctionConstants_TEST {

	static testMethod void validateConstants() {
		System.assert(AUC_AuctionConstants.RECORDTYPE_CAMPAIGN_Auction != null);
		System.assert(AUC_AuctionConstants.RECORDTYPE_OPP_AuctionDonatedItem != null);
		System.assert(AUC_AuctionConstants.RECORDTYPE_OPP_AuctionPurchasedItem != null);
		System.assert(AUC_AuctionConstants.RECORDTYPE_OPP_AuctionTicket != null);
		System.assert(AUC_AuctionConstants.RECORDTYPE_OPP_AuctionAttendee != null);

		System.assert(AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionSponsors != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors != null);

		System.assert(AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionAttendees != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionTickets != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionSponsors != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionItemDonors != null);

		System.assert(AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionDonatedItem != null);
		System.assert(AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionTicket != null);
		System.assert(AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionPurchasedItem != null);
		System.assert(AUC_AuctionConstants.OPP_NAME_SUFFIX_AuctionGift != null);

		System.assert(AUC_AuctionConstants.RECORDTYPE_OPP_AuctionGift != null);
		System.assert(AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE != null);
		System.assert(AUC_AuctionConstants.OPP_ORG_GIFT_DONOR_ROLE != null);
		System.assert(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE != null);
		System.assert(AUC_AuctionConstants.oppStageWonNotThankedProbability != null);
		System.assert(AUC_AuctionConstants.oppStageWonNotThankedForecastCategoryName != null);
		System.assert(AUC_AuctionConstants.OPP_STAGE_PLEDGED != null);
		System.assert(AUC_AuctionConstants.CAMPAIGN_Status_Default != null);
		System.assert(AUC_AuctionConstants.CROWS_PURCHASE_GRID != null);
		System.assert(AUC_AuctionConstants.StrAuctionReceiptsIntro() != null);
		System.assert(AUC_AuctionConstants.StrAuctionReceiptsFooter() != null);
		System.assert(AUC_AuctionConstants.getObjectTypeFromId(null) == null);
		System.assert(AUC_AuctionConstants.StrCreditCardValidateURLFormula() == null || AUC_AuctionConstants.StrCreditCardValidateURLFormula() != null);
		System.assert(AUC_AuctionConstants.StrCreditCardChargeURLFormula() == null || AUC_AuctionConstants.StrCreditCardChargeURLFormula() != null);
		System.assert(AUC_AuctionConstants.StrPaymentProcessorWindowParameters() != null);
		System.assert(AUC_AuctionConstants.StrPaymentProcessorPageHeight() != null);
		System.assert(AUC_AuctionConstants.fShowPaymentProcessorOnPage == AUC_AuctionConstants.fShowPaymentProcessorOnPage);
		System.assert(AUC_AuctionConstants.strOppPaymentMethodField == null || AUC_AuctionConstants.strOppPaymentMethodField != null);
		System.assert(AUC_AuctionConstants.strOppCheckNumberField == null || AUC_AuctionConstants.strOppCheckNumberField != null);
		System.assert(AUC_AuctionConstants.cRecordsPerPage > 0);
		System.assert(AUC_AuctionConstants.fAllowDuplicateBidNumbers == AUC_AuctionConstants.fAllowDuplicateBidNumbers);
		System.assert(AUC_AuctionConstants.fSetAccountOnNewAuctionOpps == AUC_AuctionConstants.fSetAccountOnNewAuctionOpps);
		System.assert(AUC_AuctionConstants.strContactHouseholdField == AUC_AuctionConstants.strContactHouseholdField);
		System.assert(AUC_AuctionConstants.strContactHouseholdNameField == AUC_AuctionConstants.strContactHouseholdNameField);
		System.assert(AUC_AuctionConstants.strContactHouseholdGreetingField == AUC_AuctionConstants.strContactHouseholdGreetingField);
		System.assert(AUC_AuctionConstants.cDonatedItemConverterBatchSize > 0);

		System.assert(AUC_AuctionConstants.ONE_TO_ONE_PROCESSOR != null);
		System.assert(AUC_AuctionConstants.BUCKET_PROCESSOR != null);
		System.assert(AUC_AuctionConstants.HH_ACCOUNT_PROCESSOR != null);

		System.assert(AUC_AuctionConstants.strNPSPAccountModel == AUC_AuctionConstants.strNPSPAccountModel);
		System.assert(AUC_AuctionConstants.isNPSPPaymentsEnabled == AUC_AuctionConstants.isNPSPPaymentsEnabled);
		System.assert(AUC_AuctionConstants.isPaymentSettingsMissing == AUC_AuctionConstants.isPaymentSettingsMissing);
		System.assert(AUC_AuctionConstants.isNPSPOneToOneAccountModel == false || AUC_AuctionConstants.isNPSPOneToOneAccountModel == true);
		System.assert(AUC_AuctionConstants.isNPSPHouseholdAccountModel == false || AUC_AuctionConstants.isNPSPHouseholdAccountModel == true);
		System.assert(AUC_AuctionConstants.IsNPSPInstalled == AUC_AuctionConstants.IsNPSPInstalled);
		System.assert(AUC_AuctionConstants.useNPSPHouseholdObject == AUC_AuctionConstants.useNPSPHouseholdObject);
	}

	static testMethod void testNoSettings() {
		delete [SELECT Id FROM AuctionSettings__c];
		validateConstants();
	}

	static testMethod void testWithSettings() {
		delete [SELECT Id FROM AuctionSettings__c];
		AuctionSettings__c stg = new AuctionSettings__c();
		stg.Allow_Duplicate_Bid_Numbers__c = true;
		stg.Auction_Receipts_Footer_1__c = 'foo';
		stg.Auction_Receipts_Footer_2__c = 'foo';
		stg.Auction_Receipts_Intro_1__c = 'foo';
		stg.Auction_Receipts_Intro_2__c = 'foo';
		stg.Campaign_Status_Default__c = 'bar';
		stg.Check_Out_Receipts_URL__c = 'http://foo.com';
		stg.Contact_Household_Field__c = 'myhousehold';
		stg.Contact_Household_Greeting_Field__c = 'greeting';
		stg.Contact_Household_Name_Field__c = 'name';
		stg.CreditCardChargeURLFormula__c = 'http://foo.com';
		stg.CreditCardValidateURLFormula__c = 'http://foo.com';
		stg.Donated_Item_Converter_Batch_Size__c = 10;
		stg.Donated_Item_Opportunity_Stages__c = 'Closed Won';
		stg.Number_of_Records_Per_Page__c = 100;
		stg.Number_of_Purchase_Grid_Rows__c = 100;
		stg.Opportunity_Check_Number_Field__c = 'check';
		stg.Opportunity_Gift_Donor_Role__c = 'gift role';
		stg.Opportunity_Gift_Org_Donor_Role__c = 'gift role';
		stg.Opportunity_Payment_Method_Field__c = 'payment';
		stg.Opportunity_Record_Type_Gift__c = 'gift';
		stg.Opportunity_Stage_Pledged__c = 'Closed Won';
		stg.Opportunity_Stage_Won_Not_Thanked__c = 'Closed Won';
		stg.Payment_Processor_Page_Height__c = '100px';
		stg.Payment_Processor_Window_Parameters__c = 'foo';
		stg.Set_Account_On_New_Opportunities__c = true;
		stg.Show_Payment_Processor_On_Page__c = true;
		stg.Ticket_Opportunity_Stages__c = 'Pledged';
		stg.Name = 'test auction settings';
		insert stg;
		System.assertNotEquals(null, stg.Id);
		System.assertNotEquals(null, AuctionSettings__c.getAll().values());
		validateConstants();
	}

	static testMethod void testGetObjectTypeFromId() {
		System.assertEquals(null, AUC_AuctionConstants.getObjectTypeFromId(null));

		Contact con = new Contact(LastName='foo');
		insert con;
		System.assertEquals(Contact.SObjectType, AUC_AuctionConstants.getObjectTypeFromId(con.Id));

		Account acc = new Account(Name='Bar');
		insert acc;
		System.assertEquals(Account.SObjectType, AUC_AuctionConstants.getObjectTypeFromId(acc.Id));

		Campaign cmp = new Campaign(Name='Baz');
		insert cmp;
		System.assertEquals(Campaign.SObjectType, AUC_AuctionConstants.getObjectTypeFromId(cmp.Id));

		String bogusId = '000000000000000000';
		System.assertEquals(null, AUC_AuctionConstants.getObjectTypeFromId(bogusId));
	}

}