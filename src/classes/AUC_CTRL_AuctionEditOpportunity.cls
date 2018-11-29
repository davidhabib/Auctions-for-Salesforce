// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionEditOpportunity { 
	
	private Opportunity opp;
	
    public AUC_CTRL_AuctionEditOpportunity(ApexPages.StandardController stdController) {
        opp = (Opportunity)stdController.getRecord(); 
        if (opp != null) {
        	opp = [SELECT Id, RecordTypeId FROM Opportunity WHERE Id = :opp.Id];
        }        
    }	

	public PageReference doEdit() {
		UTIL_Describe.checkObjectUpdateAccess('Opportunity');

		PageReference pr = null;
        Id oppRecordTypeIdNew = ApexPages.currentPage().getParameters().get('RecordType');

       	if (oppRecordTypeIdNew == null && opp.RecordTypeId == AUC_AuctionMaintenance.recordtypeIdAuctionTicket) {
       		pr = Page.AuctionNewTicketWizard;
       		pr.getParameters().put('oppId', opp.Id);
       	} else {
            pr = new PageReference('/' + opp.Id + '/e');
            pr.getParameters().put('nooverride', '1');	       	
       	}
       	pr.getParameters().put('id', opp.Id);
       	if (oppRecordTypeIdNew != null) {
       		pr.getParameters().put('RecordType', oppRecordTypeIdNew);
       	}
   		pr.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
       	return pr.setRedirect(true);
	}
}