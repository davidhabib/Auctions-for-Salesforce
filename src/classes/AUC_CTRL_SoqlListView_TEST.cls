// Written by David Habib, copyright (c) 2009-2018 DJH Consulting, djhconsulting.com
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@IsTest
public with sharing class AUC_CTRL_SoqlListView_TEST {

	static testMethod void CodeCoverageTests() {
		// create needed data
		Auction__c auction = new Auction__c (
			Name = 'Test Auction',
			Auction_Date__c = System.today()
		);
		insert auction;

		Auction_Item__c ai = new Auction_Item__c(
			Auction__c = auction.Id,
			Auction_Item_Name__c = 'Test Auction Item'
		);
		insert ai;


		//point to our VF page with the auctionId as a parameter
		PageReference p = new PageReference('Page.AuctionItems');
		p.getParameters().put('auctionId', auction.Id);
		Test.setCurrentPageReference(p);


		//instantiate the controller
		AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
		PageControllerBase pageCtrl = new AUC_CTRL_AuctionItems();
		compCtrl.pgController = pageCtrl;
		System.assertNotEquals(null, compCtrl.setCon);
		System.assert(compCtrl.NumberOfPages >= 1);
		System.assert(compCtrl.NumberOfItems >= 1);
		System.assertEquals(auction.Id, compCtrl.listSOAuctions[1].getValue());
		System.assertEquals(null, compCtrl.ChangeAuction());
		System.assertNotEquals(null, compCtrl.listPagedItem);
		System.assertEquals('%', compCtrl.strAlphaFilter);
		System.assertNotEquals(null, compCtrl.listAlphaFilters);
		compCtrl.strAlphaFilter = 'A';
		compCtrl.AlphaFilter();
		System.assertEquals(0, compCtrl.NumberOfItems);
		System.assertEquals(null, compCtrl.SortItem());
		compCtrl.strAlphaFilter = 'T';
		compCtrl.AlphaFilter();
		System.assertEquals(1, compCtrl.NumberOfItems);
		compCtrl.idEditItem = ai.Id;
		System.assertNotEquals(null, compCtrl.EditItem());
		compCtrl.idDeleteItem = ai.Id;
		System.assertEquals(null, compCtrl.DeleteItem());
		List<Auction_Item__c> listAI = [SELECT Id FROM Auction_Item__c WHERE Id = :ai.Id];
		System.assertEquals(0, listAI.size());
		compCtrl.showCheckboxes = true;
		compCtrl.isCheckedAll = false;
		System.assertNotEquals(null, compCtrl.strCookieAuctionId);
		System.assertEquals(null, compCtrl.validateId('bogusId'));
		System.assertEquals(true, compCtrl.isValidAuctionId(auction.Id));
		compCtrl.iPageNumber = 5;
		System.assertEquals(5, compCtrl.iPageNumber);
		System.assertEquals(null, compCtrl.PagingFirst());
		System.assertEquals(null, compCtrl.PagingPrevious());
		System.assertEquals(null, compCtrl.PagingNext());
		System.assertEquals(null, compCtrl.PagingLast());
	}

}