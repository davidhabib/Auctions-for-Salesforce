public with sharing class AUC_CTRL_AuctionEditOpportunity { 
	
	public Opportunity opp;
	public string mytype { get; set; }
	ApexPages.StandardController stdCtrl;
	
    public AUC_CTRL_AuctionEditOpportunity(ApexPages.StandardController stdController) {
        opp = (Opportunity)stdController.getRecord();
        stdCtrl = stdController;
        
        if (opp != null) {
        	opp = [select Id, Name, RecordTypeId from Opportunity where Id = :opp.Id];
        	if (opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionTicket) {
        		// use AuctionNewTicketWizard
        		mytype = 'use AuctionNewTicketWizard';
        	} else {
        		// use normal Opp edit page
        		mytype = 'use normal Opp edit page';
        	}
        }
    }	

	public PageReference DoEdit() {
		PageReference pr = null;
       	if (opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionTicket) {
       		pr = Page.AuctionNewTicketWizard;
       		pr.getParameters().put('oppId', opp.Id);
       		pr.getParameters().put('retURL', '/apex/AuctionTickets');
       		//new PageReference('/apex/AuctionNewTicketWizard?oppId=' + idItem + '&retURL=/apex/AuctionTickets');
       	} else {
       		//pr = stdCtrl.Edit();
       		pr = new ApexPages.StandardController(opp).Edit();
	       	pr.setRedirect(true);
       	}
       	//pr.getParameters().putAll( ApexPages.currentPage().getParameters() );
       	return pr;
	}
}