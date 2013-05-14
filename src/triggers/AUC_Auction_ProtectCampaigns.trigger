// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger AUC_Auction_ProtectCampaigns on Campaign (before delete) {

	for (Campaign cmp : trigger.old) {
		if (cmp.Auction__c != null) {
			cmp.addError ('Campaign ' + cmp.Name + ' is used by Auction: ' + cmp.Auction__c + '.  You must delete the Auction first.');			
		}
	}	

}