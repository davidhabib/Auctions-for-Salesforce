// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing virtual class ComponentControllerBase { 
	 
	public PageControllerBase pgController { 
  		get; 
    	set {
	    	if (value != null) {
				pgController = value;
				pgController.setComponentController(this);
	      	}
    	}
  	}
  	
}