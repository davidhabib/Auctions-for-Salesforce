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
	
	public override String getStrPageUniqueName() {
		return 'Tickets';
	}
	
	public override String getStrSoql() {	
		String strSoql = 'select Id, ' + String.join(listStrFields, ',') + 
				' from opportunity ' +
        		' where RecordTypeId=\'' + AUC_AuctionMaintenance.recordtypeIdAuctionTicket  + '\'' + 
        		' and CampaignId=\'' + ctrlSoqlListView.auctionMaintenance.campaignIdAuctionTickets + '\'';
		
		if (ctrlSoqlListView.strAlphaFilter != null) {
			strSoql += ' and Name like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
		}        		
       	return strSoql;			
	}

	public override PageReference NewItem() { 
		PageReference p = Page.AuctionNewTicketWizard;
		p.getParameters().put('auctionId', ctrlSoqlListView.auctionId);
		return p;		
	}
	
	public PageReference AuctionCheckIn() {
		PageReference p = Page.AuctionCheckIn;
		p.getParameters().put('auctionId', ctrlSoqlListView.auctionId);
		return p;
	}
	
	public PageReference AutoAssignBidNumbers() {
		PageReference p = Page.AuctionAutoBidNumbers;
		p.getParameters().put('auctionId', ctrlSoqlListView.auctionId);
		return p;
	}
	
	public override PageReference EditItem(Id idItem) {
		PageReference p = Page.AuctionNewTicketWizard;
		p.getParameters().put('oppId', idItem);
		p.getParameters().put('retURL', Page.AuctionTickets.getUrl());
		return p;
	}
}