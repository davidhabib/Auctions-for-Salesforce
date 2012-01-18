public with sharing class AUC_CTRL_AuctionEditOpportunity { 
	
	public Opportunity opp;
	
    public AUC_CTRL_AuctionEditOpportunity(ApexPages.StandardController stdController) {
        opp = (Opportunity)stdController.getRecord();        
        if (opp != null) {
        	opp = [select Id, Name, RecordTypeId from Opportunity where Id = :opp.Id];
        }        
    }	

	public PageReference doEdit() {
		PageReference pr = null;
       	if (opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionTicket) {
       		pr = Page.AuctionNewTicketWizard;
       		pr.getParameters().put('oppId', opp.Id);
       	} else {
            pr = new PageReference('/' + opp.id + '/e');
            pr.getParameters().put('nooverride', '1');	       	
       	}
       	pr.getParameters().put('id', opp.Id);
   		pr.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
       	return pr.setredirect(true);
	}
}