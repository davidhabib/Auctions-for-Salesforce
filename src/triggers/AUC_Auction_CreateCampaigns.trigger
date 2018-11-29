// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_Auction_CreateCampaigns on Auction__c (after insert) {

    // we are creating a new Auction, so create its three subcampaigns

	UTIL_Describe.checkCreateAccess('Campaign', new Set<String> {
		'RecordTypeId',
		'Status',
		'IsActive',
		'StartDate',
		'Name',
		UTIL_Describe.StrTokenNSPrefix('Auction_Campaign_Type__c'),
		'CampaignMemberRecordTypeId',
		UTIL_Describe.StrTokenNSPrefix('Auction__c')
	});

	UTIL_Describe.checkCreateAccess('CampaignMemberStatus', new Set<String> {
		'Label',
		'CampaignId',
		'HasResponded',
		'SortOrder',
		'IsDefault'
	});

	UTIL_Describe.checkObjectDeleteAccess('CampaignMemberStatus');

    List<Campaign> listCmpAttendees = new List<Campaign>();
    List<Campaign> listCmpTickets = new List<Campaign>();
    List<Campaign> listCmpSponsors = new List<Campaign>();
    List<Campaign> listCmpDonors = new List<Campaign>();
    List<Campaign> listCmpAll = new List<Campaign>();
    
    for (Auction__c auc : Trigger.new) {
        Campaign cmp;
        AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
                
        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = true,
            StartDate = Date.today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionAttendees,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees,
			CampaignMemberRecordTypeId = AUC_AuctionMaintenance.recordtypeIdCampaignMemberAuctionAttendee,
            Auction__c = auc.Id
            );  
        listCmpAttendees.add(cmp);
        
        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = true,
            StartDate = Date.today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionTickets,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets,
            Auction__c = auc.Id
            );  
        listCmpTickets.add(cmp);

        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = true,
            StartDate = Date.today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionSponsors,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionSponsors,
            Auction__c = auc.Id
            );  
        listCmpSponsors.add(cmp);

        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = true,
            StartDate = Date.today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionItemDonors,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors,
            Auction__c = auc.Id
            );  
        listCmpDonors.add(cmp);
    }
    
    // now create all the campaigns
    listCmpAll.addAll(listCmpAttendees);
    listCmpAll.addAll(listCmpTickets);
    listCmpAll.addAll(listCmpSponsors);
    listCmpAll.addAll(listCmpDonors);
    insert listCmpAll;
    

	// now go through each campaign and set up the correct CampaignMember statuses
	List<CampaignMemberStatus> listCMSToDel = [SELECT Id FROM CampaignMemberStatus WHERE CampaignId IN :listCmpAttendees];
    List<CampaignMemberStatus> listCMS = new List<CampaignMemberStatus>();
	
    for (Campaign cmp : listCmpAttendees) {
 	    CampaignMemberStatus cms1 = new CampaignMemberStatus(
	        Label = 'Invited',
	        CampaignId = cmp.Id,
	        HasResponded = false,
	        SortOrder = 100,
	        IsDefault = true
	    );
	    listCMS.add(cms1);
	    CampaignMemberStatus cms2 = new CampaignMemberStatus(
	        Label = 'RSVP Yes',
	        CampaignId = cmp.Id,
	        HasResponded = true,
	        SortOrder = 200
	    );
	    listCMS.add(cms2);
	    CampaignMemberStatus cms3 = new CampaignMemberStatus(
	        Label = 'RSVP No',
	        CampaignId = cmp.Id,
	        HasResponded = true,
	        SortOrder = 300
	    );
	    listCMS.add(cms3);
	    CampaignMemberStatus cms4 = new CampaignMemberStatus(
	        Label = 'Checked In',
	        CampaignId = cmp.Id,
	        HasResponded = true,
	        SortOrder = 400
	    );
	    listCMS.add(cms4);   
    } 
	
    for (Campaign cmp : listCmpDonors) {
	    CampaignMemberStatus cms5 = new CampaignMemberStatus(
	        Label = 'Donated',
	        CampaignId = cmp.Id,
	        HasResponded = true,
	        SortOrder = 100
	    );
	    listCMS.add(cms5);
    }
    
    for (Campaign cmp : listCmpTickets) {
	    CampaignMemberStatus cms6 = new CampaignMemberStatus(
	        Label = 'Donated',
	        CampaignId = cmp.Id,
	        HasResponded = true,
	        SortOrder = 100
	    );
	    listCMS.add(cms6);
    }
    
    // now save the statuses
    insert listCMS;
    delete listCMSToDel;

}