// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public abstract with sharing class PageControllerBase {
	
  	private ComponentControllerBase componentController;
	
  	public virtual ComponentControllerBase getComponentController() {
    	return componentController;
  	}

  	public virtual void setComponentController(ComponentControllerBase compController) {
    	componentController = compController;
  	}
	
  	public PageControllerBase getThis() {
    	return this;
  	}
	
	abstract public string getStrSoql();
	
	abstract public string getStrPageUniqueName();
	
	public list<string> listStrFields { get; set; }  
	
	public string strNameField { get; set; }
	
	public string strObjectType { get; set; }
	
	// whether clicking the name field should invoke the EditItem action, or just go to the object's detail page.
	public boolean fEditNameField { get; set; }

	abstract public PageReference NewItem();
	
	public AUC_CTRL_SoqlListView ctrlSoqlListView {
		get {
			if (ctrlSoqlListView == null) {
				ctrlSoqlListView = (AUC_CTRL_SoqlListView) getComponentController();
			}
			return ctrlSoqlListView;
		}
		set;
	}
	
	public virtual PageReference EditItem(ID idItem) {
		return new PageReference('/' + idItem + '/e?retURL=' + ApexPages.currentPage().getURL());
	}	

}