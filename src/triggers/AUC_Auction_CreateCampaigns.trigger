// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_Auction_CreateCampaigns on Auction__c (after insert) {

    // we are creating a new Auction, so create its three subcampaigns
    
    list<Campaign> listCmpAttendees = new list<Campaign>();
    list<Campaign> listCmpTickets = new list<Campaign>();
    list<Campaign> listCmpSponsors = new list<Campaign>();
    list<Campaign> listCmpDonors = new list<Campaign>();
    list<Campaign> listCmpAll = new list<Campaign>();
    
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
        listCmpAttendees.add(cmp);
        
        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionTickets,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets,
            Auction__c = auc.id
            );  
        listCmpTickets.add(cmp);

        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionSponsors,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionSponsors,
            Auction__c = auc.id
            );  
        listCmpSponsors.add(cmp);

        cmp = new Campaign (
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionCampaign,
            Status = AUC_AuctionConstants.CAMPAIGN_Status_Default,
            IsActive = True,
            StartDate = Date.Today(),
            Name = auc.Name + AUC_AuctionConstants.CAMPAIGN_NAME_SUFFIX_AuctionItemDonors,
            Auction_Campaign_Type__c = AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors,
            Auction__c = auc.id
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
	list<CampaignMemberStatus> listCMSToDel = [Select Id From CampaignMemberStatus WHERE CampaignId in :listCmpAttendees]; 
    list<CampaignMemberStatus> listCMS = new list<CampaignMemberStatus>();
	
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