// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionTickets extends PageControllerBase {

    // constructor
    public AUC_CTRL_AuctionTickets() {
        listStrFields = AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'AuctionTicketsTabFS');
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
        PageReference p = new PageReference('/apex/AuctionNewTicketWizard?auctionId=' + ctrlSoqlListView.auctionId);
        return p;       
    }
    
    public PageReference AuctionCheckIn() {
        PageReference p = new PageReference('/apex/AuctionCheckIn?auctionId=' + ctrlSoqlListView.auctionId);
        return p;
    }
    
    public PageReference AutoAssignBidNumbers() {
        PageReference p = new PageReference('/apex/AuctionAutoBidNumbers?auctionId=' + ctrlSoqlListView.auctionId);
        return p;
    }
    
    public override PageReference EditItem(ID idItem) {
        return new PageReference('/apex/AuctionNewTicketWizard?oppId=' + idItem + '&retURL=/apex/AuctionTickets');
    }
}