// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionTickets extends PageControllerBase {

	// constructor
	public AUC_CTRL_AuctionTickets() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'GW_Auctions__AuctionTicketsTabFS');
       	strNameField = listStrFields[0];  
       	strObjectType = 'Opportunity';	
       	fEditNameField = true;		
	}
	
	public override string getStrPageUniqueName() {
		return 'Tickets';
	}
	
	public override string getStrSoql() {	
		string strSoql = 'select Id, ' + string.join(listStrFields, ',') + 
				' from opportunity ' +
        		' where RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionTicket  + '\'' + 
        		' and CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionTickets + '\'';
		
		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' and Name like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        		
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		PageReference p = new PageReference('/apex/GW_Auctions__AuctionNewTicketWizard?auctionId=' + ctrlSoqlListView.auctionId);
		return p;		
	}
	
	public PageReference AuctionCheckIn() {
		PageReference p = new PageReference('/apex/GW_Auctions__AuctionCheckIn?auctionId=' + ctrlSoqlListView.auctionId);
		return p;
	}
	
	public PageReference AutoAssignBidNumbers() {
		PageReference p = new PageReference('/apex/GW_Auctions__AuctionAutoBidNumbers?auctionId=' + ctrlSoqlListView.auctionId);
		return p;
	}
	
	public override PageReference EditItem(ID idItem) {
		return new PageReference('/apex/GW_Auctions__AuctionNewTicketWizard?oppId=' + idItem + '&retURL=/apex/GW_Auctions__AuctionTickets');
	}
	
	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
    	// create needed data
    	Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.Today()
		);  
		insert auction;  	
    	
    	Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets and Auction__c = :auction.id];
    	System.assertEquals(auction.id, campaign.Auction__c);
    	
		AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
    	Opportunity oppDonatedItem = new Opportunity (
    		Name = 'Test Opportunity',
    		Auction_Donated_Item_Name__c = 'Test Auction Ticket',
    		Amount = 50,
    		CampaignId = campaign.id,
    		RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
    		StageName = 'Won Not Thanked',
    		CloseDate = System.Today()
    	);
    	insert oppDonatedItem;

		am.auctionId = auction.Id;
		System.assertEquals(campaign.Id, am.campaignIdAuctionTickets);
		
		//point to our VF page
		PageReference p = new PageReference('Page.AuctionTickets');
		p.getParameters().put('auctionId', auction.id); 
		Test.setCurrentPageReference(p);
		
		//instantiate the controller 
		AUC_CTRL_AuctionTickets pageCtrl = new AUC_CTRL_AuctionTickets();
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		compCtrl.pageController = pageCtrl;
		system.assert(pageCtrl.listStrFields != null);
		system.assert(pageCtrl.strNameField != null);
		system.assert(pageCtrl.getStrSoql() != null);
		system.assert(pageCtrl.NewItem() != null);
		system.assert(pageCtrl.AutoAssignBidNumbers() != null);		
	}

}