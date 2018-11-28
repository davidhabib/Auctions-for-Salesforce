// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_SoqlListView extends ComponentControllerBase { 

	// the set controller allows us to do paging in our pageTable
    public ApexPages.StandardSetController setCon {
    	get {
		    UTIL_Describe.checkObjectReadAccess(pageController.strObjectType);

            if(setCon == null) {
                String strSoql = pageController.getStrSoql();

				// start out sorting on the main name field.
                if (SortItemField == null || SortItemField == '') {
					SortItemField = pageController.strNameField;
					SortItemAsc = true;
					strAlphaFilter = '%';
                }

                if (SortItemField != null) {
                    strSoql += ' ORDER BY ' + SortItemField + (SortItemAsc ? ' ASC' : ' DESC');
                }
                // if there is no auction selected, return an empty result set.
                if (auctionId == null) {
                    strSoql = 'select Id from opportunity where Id=null';
                }
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strSoql));
                setCon.setPageSize(cRecordsPerPage);
                setCon.setPageNumber(iPageNumber);
            }
            return setCon;
        } 
        set {
        	if (setCon != value) {
        		setCon = value;
        		listPagedItem = null;
        	}
        }
    }
       
	// whether to include checkboxes in the list view       
  	public Boolean fShowCheckboxes { get; set; }
        
	// how many records per page to display
	public Integer cRecordsPerPage {
		get {
			return AUC_AuctionConstants.cRecordsPerPage;
		}
	}
	
    // how many pages in our current result set
    public Integer NumberOfPages {
    	get {
    		if (setCon != null) {
    			NumberOfPages = (setCon.getResultSize() / setCon.getPageSize()) + 1;
    		}
    		return NumberOfPages;
    	}
    	set;
    }
    
    // how many records in our current result set
    public Integer NumberOfItems {
    	get {
    		if (setCon != null) {
    			NumberOfItems = setCon.getResultSize();
    		}
    		return NumberOfItems;
    	}
    	set;
    }
	
	// constructor
	public AUC_CTRL_SoqlListView() {
		
		auctionMaintenance = new AUC_AuctionMaintenance();
		listSOAuctions = auctionMaintenance.listSOAuctions;
		String strAuctionId = ApexPages.currentPage().getParameters().get('auctionId');
		if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
			auctionId = strAuctionId;	
		} else if (validateId(strCookieAuctionId) != null && isValidAuctionId(strCookieAuctionId)) {
			auctionId = strCookieAuctionId;
		} else if (listSOAuctions != null && listSOAuctions.size() > 1) {
			auctionId = listSOAuctions[1].getValue();
		}
		setCon = null;
		auctionMaintenance.auctionId = auctionId;
		strCookieAuctionId = auctionId;
	}
	  
	// helper class we expose to our page controllers
	public AUC_AuctionMaintenance auctionMaintenance;
	
 	// the currently selected Auction
	public Id auctionId { get; set; }
	
	// the list of Auctions to put in the Auction dropdown
	public List<SelectOption> listSOAuctions { get; set; }

	// action method called when the selected Auction changes.	 
	public PageReference ChangeAuction() {
		// clear out all state that is specific to the auction
		setCon = null;
		auctionMaintenance.auctionId = auctionId;
		// update the shared Cookie
		strCookieAuctionId = auctionId;
		
		// reset all set controller Cookies for all pages
		ResetSetControllerCookies();
		
		return null;
	}
	
	// helper to reset all of the set controller Cookies for all pages 
	// useful when changing the shared auction.
	private void ResetSetControllerCookies() {
		List<Cookie> listCk = new List<Cookie>();
		for (Cookie ck : ApexPages.currentPage().getCookies().values()) {
			if (ck.getName().endsWith('SortItemField')) {
				listCk.add(new Cookie(ck.getName(), null, null, -1, false));
			} else if (ck.getName().endsWith('SortItemAsc')) {
				listCk.add(new Cookie(ck.getName(), 'true', null, -1, false));
			} else if (ck.getName().endsWith('strAlphaFilter')) {
				listCk.add(new Cookie(ck.getName(), '%', null, -1, false));
			}
		}
		
		if (listCk.size() > 0) {
			ApexPages.currentPage().setCookies(listCk);
		}
		
		// we also need to force the current page's properties over 
		// these Cookies to be reset.
		SortItemField = null;
		SortItemAsc = true;
		strAlphaFilter = '%';
	}

	// we have a seperate Cookie for AuctionId, to avoid setting it inadvertantly.
	@TestVisible private String strCookieAuctionId {
		get {
			if (strCookieAuctionId == null) {
		        Cookie cId = ApexPages.currentPage().getCookies().get('strCookieAuctionId');
		        if (cId != null) strCookieAuctionId = cId.getValue();
			}
			return strCookieAuctionId;
		}		
		set {
			if (strCookieAuctionId != value) {
				Cookie	cId = new Cookie('strCookieAuctionId', value, null, -1, false); 
	        	ApexPages.currentPage().setCookies(new Cookie[] {cId});
	        	strCookieAuctionId = value;
			}			
		}
	}
	
	// make sure it looks like a Salesforce ID
	@TestVisible private String validateId(String Idparam) {
		if (Idparam == null) return null;
        String id = String.escapeSingleQuotes(Idparam);
    	if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)) {
    		return id;
    	}
    	return null;
	}
		
	// make sure the Auction still exists
	@TestVisible private Boolean isValidAuctionId(String auctionId) {
		if (auctionId == null) return null;
		List<Auction__c> listAuc = new List<Auction__c>();
		listAuc = [SELECT Id FROM Auction__c WHERE Id = :auctionId];
		return listAuc.size() > 0;
	}
		
	// wrapper class to hold a Donated Item and a checkbox
	public class PagedItem {
		
		public SObject sobj { get; set; }
		public Boolean isChecked { get; set; }
				
		public PagedItem(SObject sobjT) {
			sobj = sobjT;
			isChecked = false;
		}
	}
		
	// returns a list of sObject's for the current page view.
	public List<PagedItem> listPagedItem {
		get {
			if (listPagedItem == null) {
				listPagedItem = new List<PagedItem>();
				for (SObject sobj : setCon.getRecords()) {
					listPagedItem.add(new PagedItem(sobj));
				}				
			}
			return listPagedItem;
		}
		set;
   	} 
   	
   	// holds the global checkbox for the header (if fShowCheckboxes is on.)
   	public Boolean isCheckedAll { get; set; }
	
	// holds the current letter we are filtering on 
	// we save this in a Cookie for the page, so we remember our place when coming back to this tab.
	public String strAlphaFilter { 
		get {
			if (strAlphaFilter == null) {
				if (pageController != null) {
			        Cookie cId = ApexPages.currentPage().getCookies().get(pageController.getStrPageUniqueName() + 'strAlphaFilter');
			        if (cId != null) strAlphaFilter = cId.getValue();
				}
			}
			return strAlphaFilter;
		}		
		set {
			if (strAlphaFilter != value) {
				if (pageController != null) {
					Cookie	cId = new Cookie(pageController.getStrPageUniqueName() + 'strAlphaFilter', value, null, -1, false);
		        	ApexPages.currentPage().setCookies(new Cookie[] {cId});
				}
	        	strAlphaFilter = value;
			}			
		}
	}
	
	// force the page to refresh when the AlphaFilter changes
	public PageReference AlphaFilter() {
		setCon = null;
		return null;
	}
	
	// a hack to provide a list of the alphabet so the component
	// can iterate over the list to create links, rather than
	// explictly listing each link in the component.
	public List<String> listAlphaFilters {
		get {
			if (listAlphaFilters == null) {
				listAlphaFilters = new List<String>{'A','B','C','D','E','F','G','H',
						'I','J','K','L','M','N','O','P','Q','R',
						'S','T','U','V','W','X','Y','Z'};
			}
			return listAlphaFilters;
		}
		set;
	}
	
	// will hold the ID of the item to be deleted
	public Id idDeleteItem { get; set; }
	
	// action method to delete an item from the database.
	public PageReference DeleteItem() {
		try {
			if (idDeleteItem != null) {
				Database.delete(idDeleteItem);
				idDeleteItem = null;
				setCon = null;
			}
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
		}
		return null;	
	}

	// will hold the ID of the item to be edit
	public Id idEditItem { get; set; }
	
	// action method to edit an item.  defer to the page controller.
	public PageReference EditItem() {
		try {
			return pageController.EditItem(idEditItem);
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
		}
		return null;	
	}
	
	// will hold the developer name of the field to be sorted
	// we save this in a Cookie for the page, so we remember our place when coming back to this tab.
	public String SortItemField { 
		get {
			if (SortItemField == null) {
				if (pageController != null) {
			        Cookie cId = ApexPages.currentPage().getCookies().get(pageController.getStrPageUniqueName() + 'SortItemField');
			        if (cId != null) SortItemField = cId.getValue();
				}
			}
			return SortItemField;
		}		
		set {
			if (SortItemField != value) {
				if (pageController != null) {
					Cookie	cId = new Cookie(pageController.getStrPageUniqueName() + 'SortItemField', value, null, -1, false);
		        	ApexPages.currentPage().setCookies(new Cookie[] {cId});
				}
	        	SortItemField = value;
			}			
		}
	}
	
	// whether current sorted ascending or descending.
	// we save this in a Cookie for the page, so we remember our place when coming back to this tab.
	public Boolean SortItemAsc { 
		get {
			if (SortItemAsc == null && pageController != null) {
		        Cookie cId = ApexPages.currentPage().getCookies().get(pageController.getStrPageUniqueName() + 'SortItemAsc');
		        if (cId != null) SortItemAsc = (cId.getValue() == 'true');
			}
			return SortItemAsc;
		}		
		set {
			if (SortItemAsc != value) {
				if (pageController != null) {
					Cookie	cId = new Cookie(pageController.getStrPageUniqueName() + 'SortItemAsc', value ? 'true' : 'false', null, -1, false);
		        	ApexPages.currentPage().setCookies(new Cookie[] {cId});
				}
	        	SortItemAsc = value;
			}			
		}
	}
	
	// action method to sort a column.
	public PageReference SortItem() {
		SortItemAsc = SortItemAsc ? false : true;
		// force a requery
		setCon = null;		
		return null;
	}

	// will hold the index of the current page
	// we save this in a Cookie for the page, so we remember our place when coming back to this tab.
	public Integer iPageNumber { 
		get {
			if (iPageNumber == null || iPageNumber == 0) {
				if (pageController != null) {
			        Cookie cId = ApexPages.currentPage().getCookies().get(pageController.getStrPageUniqueName() + 'iPageNumber');
			        if (cId != null) {
			        	String str = cId.getValue();
			        	if (str != null) {
			        		iPageNumber = Integer.valueOf(str);
			        	}
			        }
				}
			}
			if (iPageNumber == null || iPageNumber == 0) iPageNumber = 1;
			return iPageNumber;
		}		
		set {
			if (iPageNumber != value) {
				if (pageController != null) {
					Cookie cId = new Cookie(pageController.getStrPageUniqueName() + 'iPageNumber', String.valueOf(value), null, -1, false);
		        	ApexPages.currentPage().setCookies(new Cookie[] {cId});
				}
	        	iPageNumber = value;
			}			
		}
	}
	
	// actionMethod cover so we can update our PageNumber Cookie.
	public PageReference PagingFirst() {
		setCon.first();
		iPageNumber = setCon.getPageNumber();
		listPagedItem = null;
		return null;
	}

	// actionMethod cover so we can update our PageNumber Cookie.
	public PageReference PagingPrevious() {
		setCon.previous();
		iPageNumber = setCon.getPageNumber();
		listPagedItem = null;
		return null;
	}

	// actionMethod cover so we can update our PageNumber Cookie.
	public PageReference PagingNext() {
		setCon.next();
		iPageNumber = setCon.getPageNumber();
		listPagedItem = null;
		return null;
	}

	// actionMethod cover so we can update our PageNumber Cookie.
	public PageReference PagingLast() {
		setCon.last();
		iPageNumber = setCon.getPageNumber();
		listPagedItem = null;
		return null;
	}
}