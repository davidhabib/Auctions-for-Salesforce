// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class AUC_CTRL_AuctionNewTicketWizard { 
    public String strAuctionId{get;set;}
    /************C&P Code Start***************/
    public boolean processpaymentnow{set;get;}//check process payment now checkbox
    public boolean purchaseresult{set;get;}//check the payments processed or not
    /**********To get the C&P Transaction Information from C&P Transaction object**********/
    public String ReferencePayment { get; set; }
    public list<AggregateResult> getResultSet() {return ResultSet;}
    public void setResultSet(list<AggregateResult> ResultSet) {this.ResultSet= ResultSet; }
    list<AggregateResult> ResultSet;
    /**********Objects(C&P Settings & API Settings) variables declared to get the the C&P Settings information**********/
    public list<sObject> Cnpaccountlist{get;set;}
    public list<sObject> xmlvalue{get;set;}
    public boolean hideform{get;set;}//to hide the paymentdetails
    public boolean tryagain {get;set;}
    public boolean paaspackage{get;set;}//Check PaaS Existance
    public boolean transactionresult{get;set;} //Check C&P Transaction result Authorized or Declined
    public String sku{get;set;}//To collect the SKU Value
    public string TaxDeduct{get;set;}//To collect the Tax Deductible Value
    public String Payment_Type {get;set;}//To get Payment Type 
    public String OrderNumber {get;set;}//To get Order Number
    public boolean ordernumberexist{set;get;}//check ticket already processed or not
    /******To check Payment Types based on C&P Settings ***********/
    public boolean creditcardpayment{get;set;}
    public boolean echeckpayment{get;set;}
    public boolean popayment{get;set;}
    public boolean custompayment{get;set;}
    public string currencycode{get;set;} // To get Currency Code based on C&P Settings       
    map<string,string> currencycode_map = new map<string,string>();
    map<string,string> currencycode_set_map = new map<string,string>();
    map<String,String> AccountIDToGuid = new map<String,String>{};//Get the AcountGuid based on Account Number
    /**************Variables declared to call API methods*************/
    public PaaS_Class.Authentication XmlAuthentication{get;set;}
    public PaaS_Class.PaymentMethod xmlPaymentMethod{get;set;}
    public PaaS_Class xmlstring {get;set;}
    public PaaS_Class.Receipt xmlReceipt{get;set;}
    /****** To get Entry Mode *******/
    public String selecttype { get; set; }
    /************C&P Code End***************/
    
    // constructor for the class
    public AUC_CTRL_AuctionNewTicketWizard() {
        /*********C&P Code Start*************/
            
                 hideform = true;
                /******Do Intialization of PaaS__class and and its inner classes*************/
                 XmlAuthentication=new PaaS_Class.Authentication(); 
                 xmlpaymentMethod = new PaaS_Class.PaymentMethod();
                 xmlstring =new PaaS_Class();
                 xmlReceipt=new PaaS_Class.Receipt();
            /************Check the existance of PaaS by querying with Namespace Prefix*************/
                List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
                 paaspackage= false;
                if(!cls.isempty() && cls!= null){
                    paaspackage= true;
                    getpaymenttypes();
                }
        /*************C&P Code end**************/
        // get the current auction we were invoked from, and find & set the appropriate campaign.
        // NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
        // was set for the parameter, which cannot be assigned to type Id.
        
            strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
        
        // do any initialization which is not dependent on having an auctionId
            auctionMaintenance = new AUC_AuctionMaintenance();
            listSOAuctions = auctionMaintenance.listSOAuctions; 
        // create a new opp, or load existing opp if passed in
            String strOppId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('oppId'));
            if (strOppId != null && strOppId != '') {
                 string str = 'select ' + strOppFields;
                 /*******C&P Code Start*************/
                 if(paaspackage==true){
                    str +=' , CnP_PaaS__CnP_OrderNumber__c,CnP_PaaS__SKU__c,CnP_PaaS__CnP_OrderNumber__r.name,CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c,CnP_PaaS__CnP_Payment_Type__c,CnP_PaaS__Tax_deductible__c,CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Transaction_Result__c';
                 }
                  /*******C&P Code End*************/
                 str +=' from Opportunity where Id = :strOppId';
                 system.debug('sql query'+str);
                 opp = Database.Query(str);
                //opp = Database.Query('select campaign.name,' + strOppFields + ' from Opportunity where Id = :strOppId');
               
                /*********C&P Code  Start****************/
                /********Get the C&P SKU value from Opporunity(if PaaS Exists)************/
                       if(paaspackage==true){
                            if((string)opp.get('CnP_PaaS__CnP_OrderNumber__c')!=null){
                                    ordernumberexist=true;
                                    Payment_Type =(string)opp.getsObject('CnP_PaaS__CnP_OrderNumber__r').get('Cnp_paas__paymenttype__C'); 
                                    OrderNumber =(string)opp.getsObject('CnP_PaaS__CnP_OrderNumber__r').get('Name'); 
                                    if(opp.getsObject('CnP_PaaS__CnP_OrderNumber__r').get('CnP_PaaS__Transaction_Result__c')!='Declined'){
                                        transactionresult=true;
                                    }else{transactionresult=false;}
                              }else{
                                ordernumberexist=false;
                              }     
                                sku = (string)opp.get('CnP_PaaS__SKU__c');
                                 if((decimal)opp.get('CnP_PaaS__Tax_deductible__c')!=null){
                                  TaxDeduct = string.valueOf((decimal)opp.get('CnP_PaaS__Tax_deductible__c'));
                                }
                                processpaymentnow = false;
                       }  
                      
                /*********C&P Code  End****************/
                // put payment info in our temp fields
                    if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
                        strPaymentMethod = string.valueOf(opp.get(AUC_AuctionConstants.strOppPaymentMethodField));
                    }
                    if (AUC_AuctionConstants.strOppCheckNumberField != null) {
                        strCheckNumber = string.valueOf(opp.get(AUC_AuctionConstants.strOppCheckNumberField));
                    }                   
                
                // handle a non-existant contact role.
                    list<OpportunityContactRole> listCR = new list<OpportunityContactRole>();
                    listCR = [select contactId, OpportunityId, Role, IsPrimary from OpportunityContactRole where OpportunityId=:opp.Id and IsPrimary=true];
                    if (listCR.size() > 0) {        
                        contactRole = listCR[0];
                    } else {
                        contactRole = new OpportunityContactRole(); 
                        contactRole.OpportunityId = opp.Id;
                        contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
                        contactRole.IsPrimary = true;               
                    }   
                
                // always use the correct auctionId.  Don't rely on what's passed in.
                
                    if (opp.campaignId != null) {
                        Campaign cmp = [select Auction__c from Campaign where Id=:opp.CampaignId];
                        auctionId = cmp.Auction__c;
                        auctionMaintenance.auctionId = auctionId;               
                    }
                        /**********C&P Code Start**********/
                        if(paaspackage==true){
                            getcnpaccountnumber();
                        }
                        /****C&P Code End*************/
        
            } else {
                opp = new Opportunity(RecordTypeId=AUC_auctionMaintenance.recordtypeIdAuctionTicket);
                opp.CloseDate = system.Today();
                opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;  // assume new tickets are going in as paid.
                contactRole = new OpportunityContactRole(); 
                // use auctionId passed in if there, else use latest auction.
                    if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
                        auctionId = strAuctionId;
                    } else if (listSOAuctions != null && listSOAuctions.size() > 1) {
                        auctionId = listSOAuctions[1].getValue();
                    }   
                    auctionMaintenance.auctionId = auctionId;
                    opp.CampaignId = auctionMaintenance.campaignIdAuctionTickets; 
                    //decTicketFMV = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auctionId);                  
            }
        decTicketFMV = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(auctionId);
        
    } // Constructor End
    /*************C&P Code Start**************/
    //Get Account (Portal) Number from C&P API Settings
    //Note: Differenct conditions when Reference transaction exists, showing Reference Transaction as a payment method
    public void getcnpaccountnumber(){
                if(paaspackage==true && contactRole.ContactId!=null){
                    list<string> sfaccountlist=new list<string>();
                    /*******Dyanmic Query to get the Account number from Cnp Transaction Object***********/
                        list<sObject> contactlist =Database.Query('select Id,Name,CnP_PaaS__Contact__c,CnP_PaaS__vaultGuid__c,CnP_PaaS__CardExpiration__c,CnP_PaaS__TransactionDate__c,CnP_PaaS__CreditCard4x4__c,CnP_PaaS__Name_On_card__c,CnP_PaaS__Invoice_Check_Number__c,CnP_PaaS__CnPAccountID__c from CnP_PaaS__CnP_Transaction__c where CnP_PaaS__Contact__c = \'' + String.escapeSingleQuotes(contactRole.ContactId)+ '\'');
                        if(!contactlist.isEmpty()){
                            for(sObject trns:contactlist){
                                sfaccountlist.add(string.valueof(trns.get('CnP_PaaS__CnPAccountID__c')));
                            }
                        }
                        string status='Active';
                    /*******Dynamic Query to get the Account number from Api Settings Object based on Transaction object account numbers***********/
                        Cnpaccountlist=Database.Query('Select Id,Name,Cnp_paas__CnP_Account_Number__c,Cnp_paas__CnP_Account_GUID__c,Cnp_paas__Currency_Code__c  from Cnp_paas__CnP_API_Settings__c where Cnp_paas__CnP_Account_Status__c=\'' +String.escapeSingleQuotes(status) + '\' and CnP_PaaS__CnP_Account_Number__c IN :sfaccountlist');
                        if(!xmlvalue.isEmpty() && !sfaccountlist.isEmpty() ){
                                xmlauthentication.AccountID = sfaccountlist[0];                           
                        }
                        list<SelectOption> lst = getReferenceTrans();//Method for getting Reference Transaction Details
                       
                        if(!lst.isEmpty()){
                            strPaymentMethod='ReferenceTransaction';//Assign When that Account number already made some transactions
                        }else{
                             if(creditcardpayment==true){
                            strPaymentMethod='CreditCard';
                            contact con=[select id,name from contact where id=:contactrole.contactid];
                            xmlpaymentMethod.NameOnCard=con.name;
                            }
                        }                       
                }else{
                  if(creditcardpayment==true){
                 strPaymentMethod='CreditCard';
                 }
                }
    }
    public void getpaymenttypes(){
        if(paaspackage==true){
            xmlvalue = Database.Query('Select cnp_paas__Payment_Credit_Card__c,cnp_paas__Payment_Custom_Payment_Type__c,cnp_paas__Payment_eCheck__c,cnp_paas__Payment_Purchase_Order__c,cnp_paas__Payment_Invoice__c, Name,CnP_PaaS__Custom_Payment_Options__c ,cnp_paas__Contacts__c,cnp_paas__Accounts__c,cnp_paas__Opportunities__c,CnP_PaaS__Organization_Information__c,cnp_paas__Thank_You__c,Cnp_paaS__Internal_Notifications__c,cnp_paas__Terms_Conditions__c,cnp_paas__insert_contacts__c,cnp_paas__Send_receipt__c,cnp_paas__Update_Contacts__c,cnp_paas__Campaign_lp__c,cnp_paas__Account_lp__c,cnp_paas__Convenience_Fee__c,cnp_paas__Convenience_amount__c,cnp_paas__Person_Accounts__c,cnp_paas__Oppor_Stage_Name__c,cnp_paas__Stage_Declined__c,cnp_paas__Products__c,cnp_paas__Payment_For__c,cnp_paas__Amount__c,cnp_paas__Deductible_Charge__c,cnp_paas__Discount__c,cnp_paas__Shipping__c,cnp_paas__Tax__c,cnp_paas__Account_Number__c,cnp_paas__Tracker__c,cnp_paas__Campaign__c,cnp_paas__SKU__c,cnp_paas__Recurring_Type__c,cnp_paas__Recurring__c,cnp_paas__Number_Of_Installments__c,cnp_paas__Periodicity__c,cnp_paas__Disableupdate__c,cnp_paas__Custom_parameters__c from cnp_paas__XML_Setting__c LIMIT 1');  
                    /***********If PaaS exists display Payment methods && Receipt Messages based on C&P Settings***********/
                    if(!xmlvalue.isempty()){
                        xmlReceipt.SendReceipt=(boolean)xmlvalue[0].get('cnp_PaaS__Send_receipt__c');
                           if((string)xmlvalue[0].get('Cnp_paaS__Internal_Notifications__c')!= null){
                              xmlReceipt.EmailNotificationList =(String)xmlvalue[0].get('Cnp_paaS__Internal_Notifications__c');
                          }
                         if((string)xmlvalue[0].get('Cnp_paaS__Organization_Information__c')!= null){
                             xmlReceipt.OrganizationInformation =(String)xmlvalue[0].get('Cnp_paaS__Organization_Information__c');
                          }
                         if((string)xmlvalue[0].get('Cnp_paaS__Thank_You__c')!= null){
                            xmlReceipt.ThankyouMessage =(String)xmlvalue[0].get('Cnp_paaS__Thank_You__c');
                         }
                         if((string)xmlvalue[0].get('Cnp_paaS__Terms_Conditions__c')!= null){
                             xmlReceipt.TermsCondition =(String)xmlvalue[0].get('Cnp_paaS__Terms_Conditions__c');
                         }
                        if((boolean)xmlvalue[0].get('cnp_paas__Payment_Credit_Card__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_eCheck__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_Purchase_Order__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_Custom_Payment_Type__c') == false){
                                creditcardpayment = true;
                                echeckpayment = true;
                                popayment = true;
                                custompayment = true; 
                        }else{
                                creditcardpayment =(boolean)xmlvalue[0].get('cnp_Paas__Payment_Credit_Card__c');
                                echeckpayment = (boolean)xmlvalue[0].get('cnp_Paas__Payment_eCheck__c');
                                popayment = (boolean)xmlvalue[0].get('cnp_Paas__Payment_Purchase_Order__c');
                                custompayment =(boolean)xmlvalue[0].get('cnp_Paas__Payment_Custom_Payment_Type__c');   
                        }
                            if((string)xmlvalue[0].get('cnp_paaS__Account_Number__c')!=null){
                                XmlAuthentication.AccountID = (string)xmlvalue[0].get('cnp_paaS__Account_Number__c');
                                if(currencycode_set_map.get(String.valueOf(xmlvalue[0].get('cnp_paaS__Account_Number__c')))!=null){
                                    currencycode = currencycode_map.get(currencycode_set_map.get(String.valueOf(xmlvalue[0].get('cnp_paaS__Account_Number__c'))));
                                }
                                else{
                                    currencycode = '$';
                                }
                            }
                      }else{
                                creditcardpayment = true;
                                echeckpayment = true;
                                popayment = true;
                                custompayment = true;
                    } 
                    currencycode_map.put('USD','$');
                    currencycode_map.put('EUR','€');
                    currencycode_map.put('GBP','£');
                    currencycode_map.put('CAD','C$');
                    currencycode_map.put('HKD','HK$');
       }
    }
    public void processpaymentnow(){
        if(paaspackage==true){
             getpaymenttypes();
             getcnpaccountnumber();
        }
    }
    /*********C&P Code End************/
    private AUC_AuctionMaintenance auctionMaintenance;
    // the currently selected Auction
    public Id auctionId { get; set; }
    // the list of Auctions to put in the Auction dropdown
    public list<SelectOption> listSOAuctions { get; set; }
    // object to hold opportunity
    public Opportunity opp { get; set; } 
    // we instantiate this object to get the Contact lookup field. We also will save it.
    public OpportunityContactRole contactRole { get; set; }
    // the per ticket FMV to use
    public decimal decTicketFMV { get; set; }
    // helper routine to return all Opportunity field names from the Field Set
    private string strOppFields {
        get {
            if (strOppFields == null) {
                strOppFields = AUC_AuctionMaintenance.strFieldNamesFromFieldSet('Opportunity', 'AuctionNewTicketWizardFS');
                // make sure Name field is included.
                    if (!strOppFields.contains(' Name,')) strOppFields += ', Name';
                    if (!strOppFields.contains(' Auction_item_name__c,')) strOppFields += ', Auction_item_name__c';
                // make sure Number Of Tickets field is included.
                if (!strOppFields.contains(' Number_of_Tickets__c,')) strOppFields += ', Number_of_Tickets__c';
                /****************C&P Code***********************/
                   /* if(paaspackage==true){
                        if (!strOppFields.contains('CnP_PaaS__CnP_OrderNumber__r.name,')) strOppFields += ', CnP_PaaS__CnP_OrderNumber__r.name';
                        if (!strOppFields.contains('CnP_PaaS__CnP_OrderNumber__r.paymenttype__C,')) strOppFields += ', CnP_PaaS__CnP_OrderNumber__r.paymenttype__C';
                        if (!strOppFields.contains('CnP_PaaS__Tax_deductible__c,')) strOppFields += ',CnP_PaaS__Tax_deductible__c';
                    }*/
                /****************C&P Code End***********************/
                    if (!strOppFields.contains('Auction_Non_Deductible_Amount__c,')) strOppFields += ', Auction_Non_Deductible_Amount__c'; 
                    if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
                        if (!strOppFields.contains(AUC_AuctionConstants.strOppPaymentMethodField)) strOppFields += ', ' + AUC_AuctionConstants.strOppPaymentMethodField; 
                    }
                    if (AUC_AuctionConstants.strOppCheckNumberField != null) {
                        if (!strOppFields.contains(AUC_AuctionConstants.strOppCheckNumberField)) strOppFields += ', ' + AUC_AuctionConstants.strOppCheckNumberField; 
                    }                   
            }
            return strOppFields;
        }
        set;
    }
    
    // helper routine to return all CampaignMember field names from the Field Set
        private string strCMFields {
            get {
                if (strCMFields == null) {
                    strCMFields = AUC_AuctionMaintenance.strFieldNamesFromFieldSet('CampaignMember', 'AuctionNewTicketWizardFS');
                }
                return strCMFields;
            }
            set;
        }
    
    // list for Status picklist, filtered correctly for statuses for Attendees.
        public list<SelectOption> listSOStatuses {
            get {
                if (listSOStatuses == null) {
                    listSOStatuses = new list<SelectOption>();
                    
                    // since we can't seem to get the styling for a required field for Stage,
                    // we won't provide a blank option!
                    //listSOStatuses.add(new SelectOption('', ''));
                        for (CampaignMemberStatus status : [select Label from CampaignMemberStatus 
                        where IsDeleted=false and CampaignId=:auctionMaintenance.campaignIdAuctionAttendees order by SortOrder]) {
                            listSOStatuses.add(new SelectOption(status.Label, status.Label));
                        }
                }
                return listSOStatuses;
            }
            private set;
        }
    
    // the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
        public list<CampaignMember> listCmpMbrAttendees {
            set;
            get { 
                double numTickets = opp.Number_Of_Tickets__c;
                if (listCmpMbrAttendees == null) {
                    listCmpMbrAttendees = new list<CampaignMember>(); 
                    // find any existing attendees on this ticket
                        if (opp.Id != null) {
                            listCmpMbrAttendees = Database.Query('select ' + strCMFields +  
                            ' from CampaignMember where Auction_Ticket_OppId__c=\'' + String.escapeSingleQuotes(opp.Id) + '\''); 
                        }
                            
                    // create new CampaignMembers for any additional attendees on this ticket                       
                        for (integer i = listCmpMbrAttendees.size()+1; i <= numTickets; i++) {
                            CampaignMember cmpmbr = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                            cmpmbr.Table_Captain__c = contactRole.contactId;
                            cmpmbr.Status = 'RSVP Yes';
                            cmpmbr.Paid__c = (opp.amount != null);
                            // add the ticket purchaser as the first attendee
                                if (i == 1) {
                                    // but make sure they aren't already an attendee
                                        list<CampaignMember> listCmpMbr = [select Id from CampaignMember
                                        where CampaignId = :cmpmbr.CampaignId and ContactId = :contactRole.contactId];
                                        if (listCmpMbr.size() == 0) {                       
                                            cmpmbr.contactId = contactRole.contactId;
                                            cmpmbr.Is_Table_Captain__c = true;
                                        }
                                } 
                                listCmpMbrAttendees.add(cmpmbr);
                        }
                }
                return listCmpMbrAttendees;
            }
        }   
    
    // status string for reporting the results of saving.
        public String strSaveResults { get; set; }    
    
    // event handler for NumberOfTickets field being changed.
    // show the appropriate list of attendees by clearing out current state.
        public PageReference OnChange_NumberOfTickets() {
            listCmpMbrAttendees.clear();
            listCmpMbrAttendees = null;
            return null;
        }
    
    // will hold the ID of the CM to be deleted
        public ID idDeleteCM { get; set; }
    
    // action method to delete a CM from the database.
        public PageReference DeleteCM() {
            if (idDeleteCM != null) {
                database.delete(idDeleteCM);
                idDeleteCM = null;
                listCmpMbrAttendees = null;
            }
            return null;    
        }
    private class MySaveException extends Exception {}
    public PageReference Save() {
        strSaveResults = 'Starting Save...';
        try {
            // deal with scenario where user clicks directly on save without
            // having tabbed out of NumberOfTickets, thus never creating the CampaignMembers.
                if (listCmpMbrAttendees.size() == 0) {
                    OnChange_NumberOfTickets();
                }           
            
            // create or update the opp for the ticket purchase
            // verify that either contact or account is specified, but don't require both.
                if (contactRole.ContactId == null && opp.AccountId == null) {
                    throw(new MySaveException('Please specify a Contact or ' + SObjectType.Account.Label));
                }
            
            // name the opp if empty (new scenario)
            if (opp.Name == null) {
                // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
                // if so, we need to set the Opp's Account to make the rollups work.
                    if (opp.AccountId == null && contactRole.ContactId != null && AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
                        Contact contact = [select AccountId from Contact where Id=:contactRole.ContactId];
                        opp.AccountId = contact.AccountId;
                    }
                    opp.Name = auctionMaintenance.StrOppTicketName(opp.accountId, contactRole.contactId);
            }  
            opp.Auction_Non_Deductible_Amount__c = decTicketFMV * opp.Number_Of_Tickets__c;
            if (opp.StageName == null) {    
                if (opp.amount == null) {
                    opp.StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED;
                } else {
                    opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;               
                }
            }
            if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
                opp.put(AUC_AuctionConstants.strOppPaymentMethodField, strPaymentMethod);
            }
            if (AUC_AuctionConstants.strOppCheckNumberField != null && strPaymentMethod == 'Check') {
                opp.put(AUC_AuctionConstants.strOppCheckNumberField, strCheckNumber);
            }   
            /******C&P Code***********/
                if(paaspackage==true){
                    /**********store the sku value in to opportunity object********/
                        if(sku != null && sku!=''){
                            opp.put('cnp_paaS__sku__c',sku);//Assign C&P SKU to opportunity object
                        } 
                        if(TaxDeduct != null && TaxDeduct !=''){
                            opp.put('CnP_PaaS__Tax_deductible__c',decimal.valueOf(TaxDeduct));//Assign Taxdeductible to opportunity object
                        }               
                } 
            /******C&P Code End***********/            
            // save the ticket opp                                                      
                if (opp.Id == null) {
                    insert opp;
                    contactRole.OpportunityId = opp.Id;
                    contactRole.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
                    contactRole.IsPrimary = true;               
                } else {
                    update opp;
                }
            
            // if using NPSP Payments, update payment info.
                AUC_AuctionMaintenance.UpdateNPSPPayments(new list<Opportunity> { opp }, strPaymentMethod, strCheckNumber);         
            
            // if creating a new contact role, then also put the contact on the Tickets campaign.
                if (contactRole.Id == null) {
                    if (AUC_AuctionConstants.fCreateOppContactRoles(opp.Id, contactRole.ContactId)) {               
                        insert contactRole;
                    }
                // add them to the Tickets campaign.
                    if (contactRole.ContactId != null) {
                        CampaignMember cm = new CampaignMember();
                        cm.CampaignId = opp.CampaignId;
                        cm.ContactId = contactRole.ContactId;
                        cm.Status = 'Donated';
                        // note that they may already be on the tickets campaign.
                        try {
                            insert cm;
                        } catch (Exception ex) {
                            // silently handle.
                        }
                    }               
                } else {
                    update contactRole;
                }
            
            strSaveResults = 'The ticket purchase has been saved.';
            // now create the Attendee CampaignMembers
                list<CampaignMember> listCmpMbrCreate = new list<CampaignMember>();
                list<CampaignMember> listCmpMbrUpdate = new list<CampaignMember>();
                set<ID> setContactIdCreate = new set<ID>();
                for (CampaignMember cmpmbr : listCmpMbrAttendees) {
                    if (cmpmbr.Id != null) {
                        listCmpMbrUpdate.add(cmpmbr);                   
                    } else if (cmpmbr.ContactId != null) {
                        cmpmbr.CampaignId = auctionMaintenance.campaignIdAuctionAttendees;
                        if (cmpmbr.Bid_Number__c == null) cmpmbr.Bid_Number__c = null;  // force it so updates won't use previous value.
                        cmpmbr.Auction_Ticket_OppId__c = opp.id;
                        listCmpMbrCreate.add(cmpmbr);
                        setContactIdCreate.add(cmpmbr.ContactId);
                    }
                }
                update listCmpMbrUpdate;
            
            // before inserting new CM's, make sure the contacts weren't already on the Attendees campaign.
            // if they were, go ahead and delete their previous CM, and save their new CM.
                list<CampaignMember> listCmpMbrDelete = new list<CampaignMember>();
                listCmpMbrDelete = [select Id from CampaignMember where CampaignId = :auctionMaintenance.campaignIdAuctionAttendees and ContactId in :setContactIdCreate];
                delete listCmpMbrDelete;
                // now it is safe to add them            
                    insert listCmpMbrCreate;
                    strSaveResults += '  ' + String.valueOf(listCmpMbrCreate.size()) + ' contacts have been added to the auction attendee campaign.';
                    if (listCmpMbrUpdate.size() > 0) {
                        strSaveResults += '  ' + String.valueOf(listCmpMbrUpdate.size()) + ' contacts have been updated in the auction attendee campaign.'; 
                    }   
            
            // assume they already charged the card, and we don't want the page refresh to reload the payment terminal.
                /*************C&P Code Start*****************/
                   if(paaspackage==true){
                      getcnpaccountnumber();
                   }
                /*************C&P Code End*****************/
            return null;    
        
        } catch (Exception e) {
            if (opp.Id == null)
            strSaveResults = 'Error encountered while trying to save auction ticket purchase and attendees.  ';
            else
            strSaveResults = 'The ticket purchase has been saved, but errors were encountered trying to save the attendees.  ';
            ApexPages.addMessages(e);   
            // assume they already charged the card, and we don't want the page refresh to reload the payment terminal.
                fShowPanelCreditCard = false;
            return null;
        }              
    }
    
    public PageReference Cancel() {
        string retURL = ApexPages.currentPage().getParameters().get('retURL');
        if (retURL == null || retURL == '') {
            retURL = '/apex/AuctionTickets';
        }
        PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
    }
    
    public PageReference SaveAndClose() {
        Save();
        // now see if there was an error
            if (ApexPages.hasMessages()) {
                return null;
            } else {
                return Cancel();
            }
    }
    /************C&P COde Start***********/
        /*********Method declared to call the process payments********/
        public pagereference purchaseticket(){
            if(opp.Id == null){
                save();
            }
            if(opp.Id != null){
                /**************Do Initializations for C&P API Methods ****************/
                PaaS_Class.Order XmlOrder=new PaaS_Class.Order();
                PaaS_Class.BillingInformation Billing=new PaaS_Class.BillingInformation();
                PaaS_Class.BillingAddress BillingAddress=new PaaS_Class.BillingAddress();
                PaaS_Class.items itemlst = new PaaS_Class.items();
                PaaS_Class.cnpTransaction  xmltransaction=new PaaS_Class.cnpTransaction();
                PaaS_Class.Operation XmlOperation=new PaaS_Class.Operation();              
                list<PaaS_Class.items>  items = new list<PaaS_Class.items>();
                /**************Getting Reference details if Transaction already exists****************/
                if(paaspackage==true){
                    list<sObject> dupquery  = Database.Query('select Id,name,cnp_paas__vaultGuid__c from cnp_paas__CnP_Transaction__c where id=:ReferencePayment limit 1');
                    if(!dupquery.isEmpty()){
                        xmlpaymentmethod.vaultguid = (string)dupquery[0].get('cnp_paas__vaultGuid__c');
                        xmlpaymentmethod.Ordernumber =(string)dupquery[0].get('Name');
                    }
                }  
                /***************Assigning Authentication values to C&P API ****************/
                XmlAuthentication.AccountGuid =AccountIDToGuid.get(XmlAuthentication.AccountID);
                xmloperation.DeclineFraud = false;
                xmloperation.EnableRestriction = false;
                xmlstring.getOperation_node(XmlOperation);
                XmlOrder.OrderMode = 'Production';
                xmlstring.getOrder_node(XmlOrder);
                list<Paas_Class.CustomParameters> TempList=new list<Paas_Class.CustomParameters>(); 
                date charge_date =date.today(); 
                string month = String.valueOf(charge_date.month());
                string day = String.valueOf(charge_date.day());
                if(String.valueOf(charge_date.month()).length()==1){
                    month = '0'+String.valueOf(charge_date.month()); 
                }
                if(String.valueOf(charge_date.day()).length()==1){
                    day = '0'+String.valueOf(charge_date.day()); 
                }
                xmltransaction.chargedate =String.valueOf(charge_date.year()).substring(2,4)+'/'+month+'/'+day;
                xmltransaction.TransactionType = 'Payment';//For Live it is Payment for testing it is Test
                if(strPaymentMethod=='CustomPaymentType'){ 
                    xmlpaymentMethod.PaymentType='CustomPaymentType';
                }else{
                    xmlpaymentMethod.PaymentType=strPaymentMethod;
                }
                xmlstring.getPaymentMethod_node(xmlPaymentMethod);
                items = new list<PaaS_Class.items>();
                /****************If Contact already Exists *****************/
                xmlstring.CustomParameterType = 'CardHolder'; 
                if(contactRole.ContactId!= null){
                    Paas_Class.CustomParameters tempitem=new Paas_Class.CustomParameters();
                    tempitem.Field='SalesforceContactID';
                    tempitem.value=contactRole.ContactId;
                    TempList.add(tempitem);
                    xmlstring.setCustomFields_tran(TempList);
                    xmlstring.getTransactionCustomFields(xmlstring); 
                } 
                /**************Get the contact details *********/
                List<contact> contactlist = [select Id,FirstName,LastName, Email, Phone, MailingCity, MailingState, MailingCountry,  MailingPostalCode, MailingStreet, otherState,otherstreet, otherCity, otherCountry, otherPostalCode from Contact where ID =: contactRole.contactId];
                Billing.BillingFirstName = contactlist[0].FirstName;
                Billing.BillingLastName = contactlist[0].LastName;
                if(contactlist[0].Email!=null)
                    Billing.BillingEmail = contactlist[0].Email;
                if(contactlist[0].MailingStreet!=null)
                    BillingAddress.BillingAddress1 = contactlist[0].MailingStreet;
                if(contactlist[0].MailingCity!=null)
                    BillingAddress.BillingCity = contactlist[0].MailingCity;
                if(contactlist[0].MailingState!=null)
                    BillingAddress.BillingStateProvince = contactlist[0].MailingState;
                if(contactlist[0].MailingPostalCode!=null)
                    BillingAddress.BillingPostalCode = contactlist[0].MailingPostalCode;
                if(contactlist[0].Phone!=null)
                    BillingAddress.BillingPhone = contactlist[0].Phone;
                if(contactlist[0].MailingCountry!=null){
                    BillingAddress.BillingCountryCode=xmlstring.getCountryCode(contactlist[0].MailingCountry);
                }else{
                    BillingAddress.BillingCountryCode= '840';
                }
                xmlstring.getAuthentication_node(XmlAuthentication);
                xmlstring.getBillingAddress_node(BillingAddress);
                xmlstring.getBillingInformation_node(Billing);
                /**********Assigning values to Items List to insert into Opportunity Object***/
               
                itemlst  = new PaaS_Class.items();
                itemlst.ItemName = opp.name;
                if(opp.amount==0 || opp.amount==0.0){
                    xmltransaction.TransactionType = 'PreAuthorization';
                }else{
                    xmltransaction.TransactionType = 'Payment';
                }
                if(opp.Number_of_Tickets__c!=0 || opp.Number_of_Tickets__c!=0.0){
                    itemlst.UnitPrice = opp.amount/integer.valueOf(opp.Number_of_Tickets__c);
                }else{
                    itemlst.UnitPrice = opp.amount;
                }
                itemlst.UnitTax = 0.0;
                itemlst.UnitDiscount = 0.0;
                if(TaxDeduct!=null && TaxDeduct!=''){
                   if(opp.amount >= decimal.ValueOf(TaxDeduct)){
                    if(opp.Number_of_Tickets__c!=0){
                       itemlst.UnitDeductible = decimal.ValueOf(TaxDeduct)/integer.valueOf(opp.Number_of_Tickets__c);   
                    }else{
                    itemlst.UnitDeductible = decimal.ValueOf(TaxDeduct);
                    }
                    }else{
                    if(opp.Number_of_Tickets__c!=0){
                       itemlst.UnitDeductible = opp.amount/integer.valueOf(opp.Number_of_Tickets__c);   
                    }else{
                    itemlst.UnitDeductible = opp.amount;
                    }
                    }
                }else{
                itemlst.UnitDeductible = 0.0;
                }
                itemlst.SKU = sku;
                campaign camp=[select id,name from campaign where id=:opp.campaignid];
                itemlst.Campaign = camp.name;
                itemlst.CustomFieldParameters ='OpportunityID,'+opp.id+':';
                itemlst.Quantity =integer.valueOf(opp.Number_of_Tickets__c);
                items.add(itemlst); 
                xmlstring.getitemslist_node(items);                
                xmlstring.getreceipt_node(xmlReceipt);
                xmlstring.getTransactionDetails_node(xmltransaction);
                /*********Generate Xml file***********/
                xmlstring.getgeneratexml(xmlstring);
                sendapi(xmlstring.xmlfile);
                hideform = false;
            
            }
            purchaseresult=true;
            return null;
        }
        
        /*********Method declared to call the process payments and close********/
            public PageReference purchaseclose() {
                purchaseticket();
                purchaseresult=false;
                // now see if there was an error
                    if (ApexPages.hasMessages()) {
                        return null;
                    } else {
                        return Cancel();
                    }
            }
    /************C&P Code End***********/
    //==================== Support for Payment Processing ======================================
    
        // public property on whether to display the credit card panel
            public boolean fShowPanelCreditCard { get; set; }
            // public method to show the credit card panel
                public PageReference ShowPanelCreditCard() {
                    fShowPanelCreditCard = true;
                    strPaymentMethod = 'Credit Card';
                    return null;
                }
                public string strPaymentMethod { get; set; }
                public string strCheckNumber { get; set; }
                // public method called by the page when the Payment Method changes
                    public PageReference ChangePaymentMethod() {
                    // new value will be in strPaymentMethod
                        fShowPanelCreditCard = false;
                        if(contactRole.contactId != null){
                            contact con=[select name from contact where id=:contactRole.contactId];
                            xmlpaymentMethod.NameOnCard=con.name;
                        }
                        return null;
                    }   
        // public property to get the commandButton URL
        // for the Charge Credit Card button.   
        public string strCreditCardChargeURL {
            get {
                //if (strCreditCardChargeURL == null && contactRole.contactId != null) {
                    // always recompute, because we don't have callback when contactRole.contactId or opp.Amount changes.
                    { 
                        string str = AUC_AuctionConstants.StrCreditCardChargeURLFormula();
                        if (str != null) {
                            // {0} = contactId
                            // {1} = auctionId
                            // {2} = amount     
                            // {3} = sessionId
                            // {4} = partner server url
                            // {5} = organizationId
                            list<string> listFormat = new list<string>();
                            listFormat.add(contactRole.contactId);
                            listFormat.add(auctionId);
                            listFormat.add(string.valueOf(opp.Amount));
                            listFormat.add(UserInfo.getSessionId());
                            string strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
                            listFormat.add(strServerURL);                   
                            listFormat.add(UserInfo.getOrganizationId());                   
                            str = string.format(str, listFormat);           
                        }
                        strCreditCardChargeURL = str;
                    }
                    return strCreditCardChargeURL;
                    }
                private set;
            }
        
        // public property for the Window.Open() parameters
        // for the virtual terminal window.
            public string strPaymentProcessorWindowParameters {
                get {
                    return AUC_AuctionConstants.StrPaymentProcessorWindowParameters();
                }
            }
        
        // public property for whether to display the payment
        // processor's virtual terminal on our page, or in a new browser window.
            public boolean fShowPaymentProcessorOnPage {
                get {
                    return AUC_AuctionConstants.fShowPaymentProcessorOnPage;
                }
            }   
        
        // public property for the IFRAME Height parameter
        // for the virtual terminal window if displaying on our page.
            public string strPaymentProcessorPageHeight {
                get {
                    return AUC_AuctionConstants.StrPaymentProcessorPageHeight();
                }
            } 
    /***********C&P Code Start*************/
        /**********Display C&P Account Numbers from C&P Settings*****************/
        public List<SelectOption> getCnPAccount() {   
            List<SelectOption> options = new List<SelectOption>();  
            if(paaspackage==true){
                string status='Active';
                cnpaccountlist=Database.Query('Select Id,Name,Cnp_paas__CnP_Account_Number__c,Cnp_paas__CnP_Account_GUID__c,Cnp_paas__Currency_Code__c  from Cnp_paas__CnP_API_Settings__c where Cnp_paas__CnP_Account_Status__c=\'' + String.escapeSingleQuotes(status) + '\'');
                for(sObject ac:cnpaccountlist){
                    options.add(new SelectOption((string)ac.get('Cnp_paas__CnP_Account_Number__c'),(String)ac.get('Name')+' ('+(String)ac.get('Cnp_paas__CnP_Account_Number__c')+') '));
                    AccountIDToGuid.put((string)ac.get('Cnp_paas__CnP_Account_Number__c'),(string)ac.get('Cnp_paas__CnP_Account_GUID__c'));
                    currencycode_set_map.put(String.valueOf(ac.get('Cnp_paas__CnP_Account_Number__c')),String.valueOf(ac.get('Cnp_paas__Currency_Code__c')));
                    options.sort();
                    if(currencycode_map.get(String.valueOf(ac.get('Cnp_paas__Currency_Code__c')))!=null){
                    currencycode = currencycode_map.get(String.valueOf(ac.get('Cnp_paas__Currency_Code__c')));
                }else{
                    currencycode = '$'; 
                }
                }
                
                if(XmlAuthentication.AccountID!=null){
                        if(currencycode_set_map.get(XmlAuthentication.AccountID)!=null){
                             if(currencycode_map.get(currencycode_set_map.get(XmlAuthentication.AccountID))!=null){
                                 currencycode = currencycode_map.get(currencycode_set_map.get(XmlAuthentication.AccountID));
                             }
                        }
                 }
            }    
            return options;
        }
       
        /***********Call back the C&P Account Number**************/
            public void AccountChange(){
                list<SelectOption> lst = getReferenceTrans(); 
                if(!lst.isEmpty()){
                    strPaymentMethod='ReferenceTransaction';
                }else{
                    if(creditcardpayment==true){
                    strPaymentMethod='CreditCard';
                    if(contactrole.contactid!=null){
                     contact con=[select id,name from contact where id=:contactrole.contactid];
                     xmlpaymentMethod.NameOnCard=con.name;
                    }
                    }
                }
            }
        
        @future(callout=true)
        public static void sendapi(string xmlfile){
            PaaS_Class xmlstring = new PaaS_Class();
            xmlstring.Send_Transaction_api(xmlfile); 
        }   
        /*********Display Custom payment methods*************/
            public string strcustom {get;set;}
            public list<selectoption> getcusValue(){
                list<selectoption> opt = new list<selectoption>();
                if(paaspackage==true){
                    if(!xmlvalue.isEmpty()){
                        if((string)xmlValue[0].get('cnp_paas__Custom_Payment_Options__c') != null){  
                            strcustom = (string)xmlvalue[0].get('cnp_paas__Custom_Payment_Options__c');
                            string[] strlist = strcustom.split(';');
                            for(integer s=0; s<strlist.size(); s++){
                                opt.add(new selectoption(strlist[s],strlist[s]));
                            }
                        }
                    }
                }
                return opt;
            }
       
        /*************Method to get the Reference Transaction **************/
            
            public list<SelectOption> getReferenceTrans(){
                 list<sObject> dupquery =new list<sObject>();
                 list<sObject> dupquery1=new list<sObject>();
                 List<SelectOption> options = new List<SelectOption>();
                if(paaspackage==true){
                    list<AggregateResult> ResultSet1 = new list<AggregateResult>();
                    string status='Active'; 
                    string transresult= 'Authorized';
                    string payment='eCheck';
                    if((!xmlvalue.isEmpty() && (string)xmlvalue[0].get('cnp_paas__Account_Number__c') !=null)|| (xmlauthentication.AccountID!=null && xmlauthentication.AccountID!='')){
                     // Getting data from API settings 
                        Cnpaccountlist=Database.Query('Select Id,Name,cnp_paas__CnP_Account_Number__c,cnp_paas__CnP_Account_GUID__c,cnp_paas__Currency_Code__c from cnp_paas__CnP_API_Settings__c where cnp_paas__CnP_Account_Status__c=\'' + String.escapeSingleQuotes(status) + '\' and cnp_paas__CnP_Account_Number__c=\''+String.escapeSingleQuotes(XmlAuthentication.AccountID)+'\'  LIMIT 1');   
                        if(!Cnpaccountlist.isEmpty() && contactrole.contactid!=null){
                          //Querying the transactions which are paid by credit card
                            ResultSet= Database.Query('select MAX(cnp_paas__TransactionDate__c) tdate,cnp_paas__CreditCard4x4__c cardnum from cnp_paas__CnP_Transaction__c where cnp_paas__Contact__c=\''+String.escapeSingleQuotes(contactrole.contactid)+'\' and cnp_paas__CnPAccountID__c='+decimal.valueof(XmlAuthentication.AccountID)+' and cnp_paas__CreditCard4x4__c!=null and cnp_paas__Transaction_Result__c = \''+String.escapeSingleQuotes(transresult)+'\' GROUP BY cnp_paas__CreditCard4x4__c');
                             //Querying the transactions which are paid by eCheck Method  
                            ResultSet1 = Database.Query('Select Max(cnp_paas__TransactionDate__c) tdate1,cnp_paas__Check_Number__c icnum from cnp_paas__CnP_Transaction__c where cnp_paas__Contact__c =\''+String.escapeSingleQuotes(contactrole.contactid)+'\' and cnp_paas__CnPAccountID__c='+decimal.valueOf(XmlAuthentication.AccountID)+' and (cnp_paas__Invoice_Check_Number__c!=null or cnp_paas__Check_Number__c!=null) and cnp_paas__Transaction_Result__c = \''+String.escapeSingleQuotes(transresult)+'\' GROUP BY cnp_paas__Check_Number__c');
                        }
                    }
                    if((ResultSet != null && !ResultSet.isEmpty()) || (ResultSet1!=null && !ResultSet1.isEmpty())){
                        list<Datetime> transactiondate = new list<Datetime>();
                        for(AggregateResult ar : ResultSet){
                            transactiondate.add((datetime)ar.get('tdate'));
                        }
                        for(AggregateResult ar1 : ResultSet1){
                            if(ar1.get('tdate1')!=null){
                                transactiondate.add((datetime)ar1.get('tdate1'));
                            }
                        }
                            /***********Queries to retrieve most recent transactions for both Credit Card and eCheck payments **************/
                        if(contactrole.contactid !=null){
                            dupquery  = Database.Query('select Id,name, cnp_paas__TransactionDate__c,cnp_paas__Name_On_card__c,cnp_paas__CreditCard4x4__c,cnp_paas__Credit_Card_Name__c,cnp_paas__Invoice_Check_Number__c,cnp_paas__Check_Number__c,cnp_paas__vaultGuid__c,cnp_paas__CardExpiration__c,cnp_paas__PaymentType__c,cnp_paas__Transaction_Result__c from cnp_paas__CnP_Transaction__c where cnp_paas__TransactionDate__c IN :transactiondate and cnp_paas__Contact__c =\''+String.escapeSingleQuotes(contactrole.contactid)+'\' and cnp_paas__Transaction_Result__c =\''+String.escapeSingleQuotes(transresult)+'\'' );
                            dupquery1  =Database.Query('select Id,name, cnp_paas__TransactionDate__c,cnp_paas__Name_On_card__c,cnp_paas__CreditCard4x4__c,cnp_paas__Credit_Card_Name__c,cnp_paas__Invoice_Check_Number__c,cnp_paas__Check_Number__c,cnp_paas__vaultGuid__c,cnp_paas__CardExpiration__c,cnp_paas__PaymentType__c,cnp_paas__Transaction_Result__c from cnp_paas__CnP_Transaction__c where cnp_paas__TransactionDate__c IN :transactiondate and cnp_paas__Contact__c =\''+String.escapeSingleQuotes(contactrole.contactid)+'\' and cnp_paas__PaymentType__c=\''+String.escapeSingleQuotes(payment)+'\' and cnp_paas__Transaction_Result__c =\''+String.escapeSingleQuotes(transresult)+'\'');
                        }
                        Map<DateTime,String> NameonCardMap = new Map<DateTime,String>();
                        Map<DateTime,String> CardExpirationMap = new Map<DateTime,String>();
                        Map<DateTime,String> CardNumberMap = new Map<DateTime,String>();
                        Map<DateTime,string> echeckmap = new Map<DateTime,String>();
                        Map<DateTime,id> TransactionMap = new Map<DateTime,id>();
                        for(sObject tr: dupquery){
                            NameonCardMap.put((datetime)tr.get('cnp_paas__TransactionDate__c'),(string)tr.get('cnp_paas__Name_On_card__c'));
                            CardExpirationMap.put((datetime)tr.get('cnp_paas__TransactionDate__c'),(string)tr.get('cnp_paas__CardExpiration__c'));
                            CardNumberMap.put((datetime)tr.get('cnp_paas__TransactionDate__c'),(string)tr.get('cnp_paas__CreditCard4x4__c'));
                            TransactionMap.put((datetime)tr.get('cnp_paas__TransactionDate__c'),(id)tr.get('id'));
                        }
                        for(sObject tr1: dupquery1){
                            if((string)tr1.get('cnp_paas__Check_Number__c')!=null){ 
                                echeckmap.put((datetime)tr1.get('cnp_paas__TransactionDate__c'),(string)tr1.get('cnp_paas__Check_Number__c'));
                            }            
                            TransactionMap.put((datetime)tr1.get('cnp_paas__TransactionDate__c'),(id)tr1.get('id'));
                        }
                          /************Adding Values to List Options for Credit Card payment under Certain conditions************/
                        for(AggregateResult ar : ResultSet){
                            integer sysmonth = system.today().month();
                            integer sysyear = system.today().year();
                            integer expmonth,expyear;
                            
                            if(CardExpirationMap.get((datetime)ar.get('tdate'))!=null){
                                list<string> expdate = CardExpirationMap.get((datetime)ar.get('tdate')).split('/');
                                expmonth = integer.valueof(expdate[0]);
                                expyear = integer.valueof(expdate[1]);
                            }
                            if(CardNumberMap.get((datetime)ar.get('tdate'))!=null && ( expmonth >= sysmonth && expyear >= sysyear || expmonth <= sysmonth && expyear > sysyear )){
                                options.add(new SelectOption(TransactionMap.get((datetime)ar.get('tdate')),'Transaction Date: '+ar.get('tdate')+','+NameonCardMap.get((datetime)ar.get('tdate'))+':'+CardNumberMap.get((datetime)ar.get('tdate'))+','+'Expires: '+CardExpirationMap.get((datetime)ar.get('tdate'))));
                            }
                        }
                           /************Adding Values to List Options for eCheck payment under Certain conditions************/
                        for(AggregateResult ar1 : ResultSet1){
                            if(echeckmap.get((datetime)ar1.get('tdate1'))!=null){
                                options.add(new SelectOption(TransactionMap.get((datetime)ar1.get('tdate1')),'Transaction Date: '+ar1.get('tdate1')+', eCheck No:'+echeckmap.get((datetime)ar1.get('tdate1'))));
                            }
                        }
                    
                    }
                }
                
                return options;
            } 
            public void Retry(){
                tryagain = true;
                hideform = true;
                if(xmlpaymentMethod.PaymentType == 'CreditCard'){
                   xmlpaymentMethod.CardNumber = null;
                   xmlpaymentMethod.Cvv2 = null;
                }
                if(xmlpaymentMethod.PaymentType == 'Check'){
                   xmlpaymentMethod.AccountNumber= null;
                }
            } 
 
    /***********C&P Code End****************/
 }// Class End