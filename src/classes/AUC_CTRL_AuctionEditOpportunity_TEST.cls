// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_AuctionEditOpportunity_TEST {

	static testMethod void CodeCoverageTests() {
		Opportunity opp = new Opportunity(RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket);
		opp.Name = 'my bogus test ticket opportunity';
		opp.Amount = 100;
		opp.CloseDate = System.today();
		opp.StageName = 'Won Closed';
		insert opp;

		//pass Opp into the standard controller
		ApexPages.StandardController sc = new ApexPages.StandardController(opp);

		//pass the controller into the extension
		AUC_CTRL_AuctionEditOpportunity ext = new AUC_CTRL_AuctionEditOpportunity(sc);
		System.assert(ext.doEdit() != null);

		opp = new Opportunity(RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem);
		opp.Name = 'my bogus test donated item opportunity';
		opp.Amount = 100;
		opp.CloseDate = System.today();
		opp.StageName = 'Won Closed';
		insert opp;

		//pass Opp into the standard controller
		sc = new ApexPages.StandardController(opp);

		//pass the controller into the extension
		ext = new AUC_CTRL_AuctionEditOpportunity(sc);
		System.assert(ext.doEdit() != null);
	}
}