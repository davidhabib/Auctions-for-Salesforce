// Written by David Habib, copyright (c) 2009, 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_Auction_CreateCampaigns on Auction__c (after insert) {

    // we are creating a new Auction, so create its three subcampaigns
    
    list<Campaign> listCmp = new list<Campaign>();
    
    for (Auction__c auc : trigger.new) {
        Campaign cmp;
        AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
                
        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionAttendees,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees,
			CampaignMemberRecordTypeId = AUC_AuctionMaintenance.recordtypeIdCampaignMemberAuctionAttendee,
            Auction__c = auc.id
            );  
        listCmp.add(cmp);
        
        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionTickets,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets,
            Auction__c = auc.id
            );  
        listCmp.add(cmp);

        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionSponsors,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionSponsors,
            Auction__c = auc.id
            );  
        listCmp.add(cmp);

        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionItemDonors,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors,
            Auction__c = auc.id
            );  
        listCmp.add(cmp);
    }
    
    // now create them all
    insert listCmp;
    
    // create the specific CampaignMemberStatus values for the attendee campaign and delete the original ones.  
    // Also the item donors campaign and tickets campaign.
    Id cmpIdAttendees = listCmp[0].Id;  
    Id cmpIdItemDonors = listCmp[3].Id;
    Id cmpIdTickets = listCmp[1].Id;
    
    list<CampaignMemberStatus> listCMSToDel = [Select Id From CampaignMemberStatus WHERE CampaignId = :cmpIdAttendees]; 
    list<CampaignMemberStatus> listCMS = new list<CampaignMemberStatus>();
    
    CampaignMemberStatus cms1 = new CampaignMemberStatus(
        Label = 'Invited',
        CampaignId = cmpIdAttendees,
        HasResponded = false,
        SortOrder = 100,
        IsDefault = true
    );
    listCMS.add(cms1);

    CampaignMemberStatus cms2 = new CampaignMemberStatus(
        Label = 'RSVP Yes',
        CampaignId = cmpIdAttendees,
        HasResponded = true,
        SortOrder = 200
    );
    listCMS.add(cms2);

    CampaignMemberStatus cms3 = new CampaignMemberStatus(
        Label = 'RSVP No',
        CampaignId = cmpIdAttendees,
        HasResponded = true,
        SortOrder = 300
    );
    listCMS.add(cms3);
    
    CampaignMemberStatus cms4 = new CampaignMemberStatus(
        Label = 'Donated',
        CampaignId = cmpIdAttendees,
        HasResponded = true,
        SortOrder = 400
    );
    listCMS.add(cms4);    

    CampaignMemberStatus cms5 = new CampaignMemberStatus(
        Label = 'Donated',
        CampaignId = cmpIdItemDonors,
        HasResponded = true,
        SortOrder = 100
    );
    listCMS.add(cms5);

    CampaignMemberStatus cms6 = new CampaignMemberStatus(
        Label = 'Donated',
        CampaignId = cmpIdTickets,
        HasResponded = true,
        SortOrder = 100
    );
    listCMS.add(cms6);

    insert listCMS;
    delete listCMSToDel;

}