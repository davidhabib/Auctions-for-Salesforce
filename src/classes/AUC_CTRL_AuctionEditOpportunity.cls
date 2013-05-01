// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

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
        ID oppRecordTypeIdNew = ApexPages.currentPage().getParameters().get('RecordType');       

       	if (oppRecordTypeIdNew == null && opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionTicket) {
       		pr = Page.AuctionNewTicketWizard;
       		pr.getParameters().put('oppId', opp.Id);
       	} else {
            pr = new PageReference('/' + opp.id + '/e');
            pr.getParameters().put('nooverride', '1');	       	
       	}
       	pr.getParameters().put('id', opp.Id);
       	if (oppRecordTypeIdNew != null) {
       		pr.getParameters().put('RecordType', oppRecordTypeIdNew);
       	}
   		pr.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
       	return pr.setredirect(true);
	}
	
	//==================== TEST METHOD(s) ======================================
	static testmethod void CodeCoverageTests() {
		Opportunity opp = new Opportunity(RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket);
		opp.Name = 'my bogus test ticket opportunity';
		opp.Amount = 100;
		opp.CloseDate = system.today();
		opp.StageName = 'Won Closed';
		insert opp;
		
		//pass Opp into the standard controller
		ApexPages.StandardController sc = new ApexPages.standardController(opp);
		
		//pass the controller into the extension
		AUC_CTRL_AuctionEditOpportunity ext = new AUC_CTRL_AuctionEditOpportunity(sc);		
		System.assert(ext.doEdit() != null);		
		
		opp = new Opportunity(RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem);
		opp.Name = 'my bogus test donated item opportunity';
		opp.Amount = 100;
		opp.CloseDate = system.today();
		opp.StageName = 'Won Closed';
		insert opp;
		
		//pass Opp into the standard controller
		sc = new ApexPages.standardController(opp);
		
		//pass the controller into the extension
		ext = new AUC_CTRL_AuctionEditOpportunity(sc);		
		System.assert(ext.doEdit() != null);				
	}	
}