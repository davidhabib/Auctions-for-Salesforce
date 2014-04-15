// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckOut {
    /**********C&P Code Start**********/
    public String selecttype { get; set; }//Check CreditCard Entry Mode
    public boolean paaspackage{get;set;} //Check C&P PaaS existance
    public map<string,boolean> transactionresult{get;set;} //Check C&P Transaction result Authorized or Declined
    public map<string,boolean> ordernumberexist{get;set;} //Check C&P Order Number existance
     /**********To get the C&P Transaction information from C&P Transaction object**********/
    public String ReferencePayment { get; set; }
    public list<AggregateResult> getResultSet() {return ResultSet;}
    public void setResultSet(list<AggregateResult> ResultSet) {this.ResultSet= ResultSet; }
    list<AggregateResult> ResultSet;
    /**********Objects(C&P Settings &  C&P API_Settings)declared to get the C&P Settings information**********/
    public list<sObject> Cnpaccountlist{get;set;}
    public list<sObject> xmlvalue{get;set;}
    /******Variables declared to check Payment types based on C&P Settings Object***********/
    public boolean creditcardpayment{get;set;}
    public boolean echeckpayment{get;set;}
    public boolean popayment{get;set;}
    public boolean custompayment{get;set;}
    /**************Variables declared to call API*************/
    public PaaS_Class.Authentication XmlAuthentication{get;set;}
    public PaaS_Class xmlstring{get;set;}
    public PaaS_Class.PaymentMethod xmlPaymentMethod{get;set;}
    public PaaS_Class.Receipt xmlReceipt{get;set;}
    /********** variables declared to hide the Payment Details***********/
    public boolean hideform{get;set;}
    public boolean paymentform{set;get;}
    public boolean tryagain {get;set;}// Variable to show Payments if Transaction Declined
    Map<String,String> AccountIDToGuid = new Map<String,String>{};//Get the AcountGuid based on Account Number
    
     /**********C&P Code End**********/
    // constructor
    public AUC_CTRL_AuctionCheckOut() {
        paymentform=true;
        hideform = true;        
        // force IE into Standards Mode
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
        auctionMaintenance = new AUC_AuctionMaintenance();
        listSOAuctions = auctionMaintenance.listSOAuctions;
        
        String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
        if (strAuctionId != null && strAuctionId != '' && strAuctionId != 'null') {
            auctionId = strAuctionId;   
        } else if (listSOAuctions != null && listSOAuctions.size() > 1) {
            auctionId = listSOAuctions[1].getValue();
        }
        auctionMaintenance.auctionId = auctionId;   

        // handle the no auction case
        if (auctionId == null) {
            strSaveResults = 'You must first create an Auction before using this page.';
        } 
        /***************C&P Code Start******/
       
         /*************Check if PaaS Package exists or not*************/
         List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
         paaspackage=false;
          /******Do Intialization of Paas__class and and its inner classes*************/
         XmlAuthentication=new PaaS_Class.Authentication(); 
              xmlpaymentMethod = new PaaS_Class.PaymentMethod();
              xmlstring =new PaaS_Class();
               xmlReceipt=new PaaS_Class.Receipt();  
         if(cls!= null && !cls.isempty())
           {
             paaspackage= true;
             xmlvalue = Database.Query('Select cnp_paas__Payment_Credit_Card__c,cnp_paas__Payment_Custom_Payment_Type__c,cnp_paas__Payment_eCheck__c,cnp_paas__Payment_Purchase_Order__c,cnp_paas__Payment_Invoice__c, Name,CnP_PaaS__Custom_Payment_Options__c ,cnp_paas__Contacts__c,cnp_paas__Accounts__c,cnp_paas__Opportunities__c,CnP_PaaS__Organization_Information__c,cnp_paas__Thank_You__c,Cnp_paaS__Internal_Notifications__c,cnp_paas__Terms_Conditions__c,cnp_paas__insert_contacts__c,cnp_paas__Send_receipt__c,cnp_paas__Update_Contacts__c,cnp_paas__Campaign_lp__c,cnp_paas__Account_lp__c,cnp_paas__Convenience_Fee__c,cnp_paas__Convenience_amount__c,cnp_paas__Person_Accounts__c,cnp_paas__Oppor_Stage_Name__c,cnp_paas__Stage_Declined__c,cnp_paas__Products__c,cnp_paas__Payment_For__c,cnp_paas__Amount__c,cnp_paas__Deductible_Charge__c,cnp_paas__Discount__c,cnp_paas__Shipping__c,cnp_paas__Tax__c,cnp_paas__Account_Number__c,cnp_paas__Tracker__c,cnp_paas__Campaign__c,cnp_paas__SKU__c,cnp_paas__Recurring_Type__c,cnp_paas__Recurring__c,cnp_paas__Number_Of_Installments__c,cnp_paas__Periodicity__c,cnp_paas__Disableupdate__c,cnp_paas__Custom_parameters__c from cnp_paas__XML_Setting__c LIMIT 1');  
            /***********If Paas exists Display Payment methods && Receipt Messages based on C&P  settings***********/
              if(!xmlvalue.isempty())
                {
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
                  //C&P settings dont have any conditions, by default put the values as TRUE 
                 if((boolean)xmlvalue[0].get('cnp_paas__Payment_Credit_Card__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_eCheck__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_Purchase_Order__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_Custom_Payment_Type__c') == false){
                         creditcardpayment = true;
                         echeckpayment = true;
                         popayment = true;
                         custompayment = true; 
                }else{
                 //C&P settings values
                         creditcardpayment =(boolean)xmlvalue[0].get('cnp_Paas__Payment_Credit_Card__c');
                         echeckpayment = (boolean)xmlvalue[0].get('cnp_Paas__Payment_eCheck__c');
                         popayment = (boolean)xmlvalue[0].get('cnp_Paas__Payment_Purchase_Order__c');
                         custompayment =(boolean)xmlvalue[0].get('cnp_Paas__Payment_Custom_Payment_Type__c');   
                    }
               if((string)xmlvalue[0].get('cnp_paaS__Account_Number__c')!=null){
                   XmlAuthentication.AccountID = (string)xmlvalue[0].get('cnp_paaS__Account_Number__c');
                }
              }/**********If no record exist in the C&P Settings ...Dispaly all Payment Types**********/
         else{
                  creditcardpayment = true;
                  echeckpayment = true;
                  popayment = true;
                  custompayment = true;
            } 
        }
   
    /*******************C&P Code End *******************/
    } // Constructor Close

    private AUC_AuctionMaintenance auctionMaintenance;

    // private status string for reporting the results of saving.
    private String strSaveResults { get; set; } 
    
    // helper routine to return all Opportunity field names
    private string strOppFields {
        get {
            if (strOppFields == null) {             
                // initialize the list of all fields on Opportunity.
                // we could have just queried the field set, but our page also looks at
                // multiple other Opp fields, so it is easiest to just get them all.
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Opportunity.fields.getMap();
                list<string> listStrFields = new list<string>();
                listStrFields.addAll(mapS.keySet());  
                strOppFields = '';
                for (string str : listStrFields) {
                if(str!='lastvieweddate' && str!='lastreferenceddate'){
                    strOppFields += 'Opportunity.' + str + ',';}
                  }
             strOppFields = strOppFields.substring(0, strOppFields.length()-1);
            }
            return strOppFields;
        }
        set;
    }    
    
    // the currently selected Auction 
    public Id auctionId { get; set; }
    
    // the list of Auctions to put in the Auction dropdown
    public list<SelectOption> listSOAuctions { get; set; }
     
    // action method called when the auction dropdown is changed.    
    public PageReference ChangeAuction() {
        // clear out all state that is specific to the auction
        auctionMaintenance.auctionId = auctionId;
        listReceipts = null;
        contactIdPurchaser = null;
        strSaveResults = null;
        return null;
    }

    // holds the currently selected Purchaser contact
    // has to be a string to allow a null Id ('') to get returned from the page.
    public string contactIdPurchaser { 
        get; 
        set {
            // first invalidate anything dependent on a change
            if (contactIdPurchaser != value) {
                strNamePurchaser = null;
                strBidderNumber = null;
                listReceipts = null;
                strCreditCardChargeURL = null;
                strOpenReceiptURL = null;
                fShowPanelCreditCard = false;
                //strPaymentMethod = null;
                strCheckNumber = null;
                fOppsToUpdate = false;
            }
            contactIdPurchaser = value;
            if (contactIdPurchaser == '') contactIdPurchaser = null; 
        }       
    }
    
    // holds the currently selected Purchaser's name (and bid number)   
    public string strNamePurchaser { 
        get {
            if (strNamePurchaser == null && contactIdPurchaser != null) {
                Contact con = [select Name from Contact where Id = :contactIdPurchaser];
                strNamePurchaser = con.Name;
                if (strBidderNumber != null) strNamePurchaser += ' - ' + strBidderNumber; 
            }
            return strNamePurchaser;
        }
        private set;
    }
    
    private string strBidderNumber {
        get {
            if (strBidderNumber == null && contactIdPurchaser != null) {                
                list<CampaignMember> listCm = [select contactId, Bid_Number__c from CampaignMember 
                    where (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees or
                    CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
                    and contactId = :contactIdPurchaser];
                if (listCm.size() > 0 ) {
                    strBidderNumber = (listCm[0].Bid_Number__c == null ? '' : string.valueOf(integer.valueOf(listCm[0].Bid_Number__c)));
                }
            }
            return strBidderNumber;
        }
        private set;        
    } 
            
    // callback when the user changes the Purchaser contact lookup.
    public PageReference ChangePurchaserLookup() {
        // clear any previous save message
        strSaveResults = null;
       /************C&P Code Start***************/
        if(paaspackage==true){     
              if(contactidpurchaser!=null && contactidpurchaser!='') {
                   list<string> sfaccountlist=new list<string>();
                    /*******Dynamic Query to get the Account number from C&P Transaction Object***********/
                    list<sObject> contactlist =Database.Query('select Id,Name,CnP_PaaS__Contact__c,CnP_PaaS__vaultGuid__c,CnP_PaaS__CardExpiration__c,CnP_PaaS__TransactionDate__c,CnP_PaaS__CreditCard4x4__c,CnP_PaaS__Name_On_card__c,CnP_PaaS__Invoice_Check_Number__c,CnP_PaaS__CnPAccountID__c from CnP_PaaS__CnP_Transaction__c where CnP_PaaS__Contact__c = \'' + String.escapeSingleQuotes(contactidpurchaser)+ '\'');
                      if(!contactlist.isEmpty()){
                           for(sObject trns:contactlist){
                              sfaccountlist.add(string.valueof(trns.get('CnP_PaaS__CnPAccountID__c')));
                            }
                        }
                    string status='Active';
                    /*******Dyanmic Query to get the Account number from Api Settings Object based on Transaction object account numbers***********/
                    Cnpaccountlist=Database.Query('Select Id,Name,Cnp_paas__CnP_Account_Number__c,Cnp_paas__CnP_Account_GUID__c,Cnp_paas__Currency_Code__c  from Cnp_paas__CnP_API_Settings__c where Cnp_paas__CnP_Account_Status__c=\'' + status + '\' and CnP_PaaS__CnP_Account_Number__c IN :sfaccountlist');
                    if((!xmlvalue.isEmpty() && (string)xmlvalue[0].get('cnp_paas__Account_Number__c')!=null) || (!sfaccountlist.isEmpty())){
                          if(!sfaccountlist.isEmpty()){
                            xmlauthentication.AccountID = sfaccountlist[0];
                        }
                    }
              list<SelectOption> lst = getReferenceTrans();
              if(!lst.isEmpty()){
                 strPaymentMethod='ReferenceTransaction';
               } else{
                      if(creditcardpayment==true){
                     strPaymentMethod='CreditCard';
                     if(contactIdPurchaser!=null){
                     Contact con = [select Name from Contact where Id = :contactIdPurchaser];
                     xmlpaymentMethod.NameOnCard=con.name;
                     }
                     }
               }
               
           }
     } 
     /***********C&P Code End*************/
 // the setter for contactIdPurchaser will
  // automatically invalidate any dependencies!
        return null;
  }  
    // this parameter is used in scenarios where the page
    // needs us to search for an Purchaser before it could wait
    // for the return from its javascript remoting call to get data
    public string searchPurchaser { get; set; }
    
    // callback when the user changes the Attendee contact lookup and submits too quick.
    public PageReference SearchPurchaserLookup() {
        if (searchPurchaser != null && searchPurchaser != '') {

            // need to search by both contact name and bid number
            decimal decBid = -1;
            try {
                decBid = decimal.valueOf(searchPurchaser);
            } catch (Exception ex) {}
            list<CampaignMember> listCM = [select contactId, contact.Name, Bid_Number__c from CampaignMember 
                where (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees or
                        CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
                    and contactId <> null
                    and (contact.Name = :searchPurchaser or Bid_Number__c = :decBid)];
            if (listCM.size() > 0) {
                contactIdPurchaser = listCM[0].contactId;
            } else {
                contactIdPurchaser = null;
                strSaveResults = null;
                strNamePurchaser = searchPurchaser; // to keep displaying the text.
                return null;
            }
        } else {
            contactIdPurchaser = null;  
            strNamePurchaser = null;    
            strBidderNumber = null; 
        }
      
        return ChangePurchaserLookup();
    }

    // status string for reporting helpful instructions and the results of saving.
    public string strStatus {
        
        get {
            boolean fPurchaser = contactIdPurchaser != null && contactIdPurchaser != '';
            boolean fSearchPurchaser = searchPurchaser != null && searchPurchaser != '';
            boolean fPurchases = listReceipts.size() > 0 && 
                listReceipts[0].listOppAuctionPurchases.size() > 0;
            
            if (strSaveResults != null) {
                strStatus = strSaveResults;
            } else if (!fPurchaser && !fSearchPurchaser) {
                strStatus = 'Enter the name or bid number of a guest to display purchases.'; 
            } else if (!fPurchaser && fSearchPurchaser) {
                strStatus = 'No attendee found by that name for the selected auction.';
            } else if (fPurchaser && !fPurchases) {
                strStatus = 'Guest has no purchases entered for the selected auction.';
            } else if (fPurchaser && fPurchases && paaspackage==false) {
                strStatus = '1. Check <b> Pay Now </b> for the purchases you wish to process.';  
                strStatus += ' 2. Choose the Payment Method.';
                if (strCreditCardChargeURL != null) {               
                      strStatus += '&nbsp;&nbsp;<b>Credit Card</b> will open a new ' + (fShowPaymentProcessorOnPage ? 'panel' : 'window') + ' to process the charge.';
                }
                strStatus += '<br/>3. Click <b>Update Opportunities</b> to complete processing.';
                strStatus += '<br/>4. Continue with next steps.';
            }
            else if (fPurchaser && fPurchases && paaspackage==true) {
                strStatus = '1. Check <b>Pay Now</b> for the purchases you wish to process.';  
                strStatus += '<br/>2. Choose the Payment Method.';
                strStatus += '<br/>3.Continue with next steps.';
            }
            return strStatus;
        }
        private set;
    }
    
    // boolean to track when the purchaser's opportunities need to be updated
    public boolean fOppsToUpdate { get; set; }

    //==================== Purchaser Class ======================================
    // helper class that holds a contact, and their bid number
    global class Purchaser {        
        global Purchaser() {}       
        global ID contactId { get; set; }
        global string strBidderNumber { get; set; }
        global string strName { get; set; }     
    }

    /*******************************************************************************************************
    * @description Javascript Remoting method to return a list of Contacts who purchased Auction Items
    * or Auction Tickets on the specified auction, optionally filtered by strFilter.
    * @param auctionId the Auction to filter by 
    * @param strFilter the substring to filter by 
    * @return list<Purchaser>, which will be turned into a Javascript collection.
    ********************************************************************************************************/
   @RemoteAction global static list<Purchaser> getListPurchasers(string auctionId, string strFilter) {
        if (auctionId == null || auctionId == '') return null;
        AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
        auctionMaintenance.auctionId = auctionId;

        // hold a map from contact ID's to their Campaign Members.
        map<ID, CampaignMember> mapContactIdCM = new map<ID,CampaignMember>();
        
        // this list will hold the same contactID's, but in their sorted order, so we can
        // return an alphabetized list.
        list<ID> listContactId = new list<ID>();
        
        strFilter = '%' + strFilter + '%';      
        
        // grab all contacts off the Attendees and Tickets campaign
        for (list<CampaignMember> listCM : [select contactId, contact.Name, Bid_Number__c from CampaignMember 
            where (CampaignId = :auctionMaintenance.campaignIdAuctionAttendees or
                    CampaignId = :auctionMaintenance.campaignIdAuctionTickets) 
                and contactId <> null
                and contact.Name like :strFilter
                and Status <> 'RSVP No'
            order by contact.LastName, contact.FirstName]) {
            
            for (CampaignMember cm : listCM) {              
                // if the contact isn't already in the map with a bid number, put them in.
                CampaignMember cmIn = mapContactIdCM.get(cm.contactId);
                if (cmIn == null || (cmIn.Bid_Number__c == null && cm.Bid_Number__c != null)) {
                    mapContactIdCM.put(cm.contactId, cm);
                    // only add them to this list once
                    if (cmIn == null) listContactId.add(cm.contactId);
                }
            }
        }
                        
        // create our list of purchasers
        list<Purchaser> listPurchaser = new list<Purchaser>();
        for (ID conId : listContactId) {
            CampaignMember cm = mapContactIdCM.get(conId);
            Purchaser p = new Purchaser();
            p.contactId = cm.contactId;
            p.strName = cm.contact.Name;
            p.strBidderNumber = (cm.Bid_Number__c == null ? '' : string.valueOf(integer.valueOf(cm.Bid_Number__c)));
            listPurchaser.add(p);
        }
        return listPurchaser; 
    }   
    
    // are there any purchase opportunities to display?
    public Boolean fHasReceipts {
        get {
            if (listReceipts == null) return False;
            if (listReceipts.size() == 0) return False;
            return True;
        }
    }
    
    // list of Receipt objects to display
    public list<Receipt> listReceipts {
        get {
            if (listReceipts != null) {
                return listReceipts;
            }
            
            // create the list of which contacts to include
            list<ID> listContactId = new list<ID>();
            if (contactIdPurchaser != null) {
                listContactId.add(contactIdPurchaser);
            }
            // call the real worker.
            listReceipts = listReceiptsForlistContactId(listContactId);
            // force the totals to recalc
            RecalcTotalAmountToPay(listReceipts);                   
            return listReceipts;
        }   
    
        set;        
    }
    
    // this is the core of the work.  Getting a list of Receipts for contacts who made purchases.
    // each receipt contains a list of the opportunities for the contact.
    // this allows us to use two apex:repeat constructs to loop through the contacts, and all of their opps.
    // CheckOut doesn't need to handle multiple contacts, but we copied this from AuctionsReceipts which does.
    private list<Receipt> listReceiptsForlistContactId(list<ID> listContactId) {            
            
            list<Receipt> listReceiptsT = new list<Receipt>();
            Date dtAuction = AUC_AuctionMaintenance.DateOfAuctionId(auctionId);
            map<ID, Receipt> mapContactIdReceipt = new map<ID, Receipt>();
            string rtPurchase = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem;
            string rtGift = AUC_AuctionMaintenance.recordtypeIdAuctionGift;
            string rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
            string cmpIdAttendees = auctionMaintenance.campaignIdAuctionAttendees;
            string cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;
            string strSoql = 'select contactId, contact.Name, contact.Firstname, contact.MailingStreet, contact.MailingCity, contact.MailingState, contact.MailingPostalCode, ';
                if(paaspackage==true){
                    strSoql+='opportunity.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Transaction_Result__c,';
                 }
                strSoql+='opportunity.RecordType.Name,opportunity.Auction_Item_Purchased__r.Show_Tax_Deductible__c,opportunity.Auction_Item_Purchased__r.Total_Tax_Deductible__c,opportunity.Auction_Item_Purchased__r.sku__c,opportunity.Auction_Item_Purchased__r.Token_Value__c,opportunity.Auction_Item_Purchased__r.Fair_Market_Value__c, ' + AUC_AuctionMaintenance.StrEscape(strOppFields) +
                ' from OpportunityContactRole ' +
                ' where IsPrimary=true and contactId in :listContactId and ' +
                    ' (((opportunity.RecordTypeId = :rtPurchase or opportunity.RecordTypeId = :rtGift) ' + 
                        ' and opportunity.campaignId = :cmpIdAttendees) ' +
                    ' or ' +  
                    ' (opportunity.RecordTypeId = :rtTicket ' +
                        ' and opportunity.campaignId = :cmpIdTickets ' +
                        ' and IsPrimary=true)) ' +
                    ' order by contact.LastName, contact.FirstName';


            for (list<OpportunityContactRole> listOCR : database.query(strSoql)) {
                    auctionopportunity=new list<opportunity>();
                // now go through all the opps, and for each contact create the appropriate Receipt objects and their child opportunities.     
                    transactionresult=new map<string,boolean>();
                    ordernumberexist=new Map<string,boolean>();    
                for (OpportunityContactRole ocr : listOCR){
                    Opportunity opp = ocr.Opportunity;
                    auctionopportunity.add(opp);
                    Receipt r = mapContactIdReceipt.get(ocr.contactId);
                    if (r == null) {
                        r = new Receipt();
                        r.contactId = ocr.contactId;
                        r.auctionId = auctionId;
                        r.listOppAuctionPurchases = new list<AUC_PurchaseOpportunity>();
                        r.strContactName = ocr.Contact.Name;
                        r.strContactFirstName = ocr.Contact.FirstName;
                        r.dtAuction = dtAuction;
                        mapContactIdReceipt.put(r.contactId, r);
                        listReceiptsT.add(r);
                    }
                    AUC_PurchaseOpportunity po = new AUC_PurchaseOpportunity(ocr.opportunity);
                    if(paaspackage==true){
                   
                         if(po.opp.get('CnP_PaaS__CnP_OrderNumber__c')!=null){
                         if(po.opp.getsObject('CnP_PaaS__CnP_OrderNumber__r').get('CnP_PaaS__Transaction_Result__c')!='Declined'){
                                 transactionresult.put(po.opp.id,true);
                          }else {
                                 po.IsPayNow=true;
                                transactionresult.put(po.opp.id,false);
                           }  
                                                   
                           ordernumberexist.put(po.opp.id,true);
                           system.debug('ordernumberexistordernumberexistordernumberexistordernumberexist'+ordernumberexist);
                         }else{
                           ordernumberexist.put(po.opp.id,false);
                           transactionresult.put(po.opp.id,false);
                         }
                      }else{
                           ordernumberexist.put(po.opp.id,false);
                           transactionresult.put(po.opp.id,false);
                      }
                      system.debug('ordernumberexistordernumberexist'+ordernumberexist);
                    r.listOppAuctionPurchases.add(po);
                    if (opp.Amount <> null) {
                    
                        r.decTotalAmountPaid += opp.Amount;
                        if (po.IsPayNow) {
                       /**************C&P Code Start**************/
                       opppaynowboolean.put(po.opp.id,po.IsPayNow);
                       /**************C&P Code End**************/
                            r.decTotalAmountToPay += opp.Amount;
                            fOppsToUpdate = true;
                           
                        }
                        
                    }
                    //r.decTotalAmountDeductible += opp.Auction_Deductible_Amount__c;
                    //if (opp.IsWon) r.decTotalAmountReceived += opp.Amount;
                }
            }
            return listReceiptsT;
    }
    
    // utility to go through all receipts, and retotal how much they plan to pay.
    public void RecalcTotalAmountToPay(list<Receipt> listR) {
        if (listR == null) return;
        
        for (Receipt r : listR) {
            r.decTotalAmountToPay = 0;
              
            for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
             /**************C&P Code Start**************/
             if(po.IsPayNow==false){
                opppaynowboolean.remove(po.opp.id);
                }
                /**************C&P Code End**************/
                if (po.IsPayNow && po.opp.Amount != null) {
                  r.decTotalAmountToPay += po.opp.Amount;
                }
            }
        }
        // force this url to get refreshed with the new amount.
        strCreditCardChargeURL = null;
    }
            
    // utility to count how many opps are checked.
    integer cnt = 0;
    private integer CountCheckOpps(list<Receipt> listR) {
        if (listR == null) return 0;
        //integer cnt = 0;
        for (Receipt r : listR) {
            for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
                if (po.IsPayNow) {
                    cnt++;
                }
            }
        }
        return cnt;
    }

    //==================== Receipt Class ======================================
    // helper class that holds a contact, and their opportunities
    // the VF Page will iterate through a list of these that the controller provides.
    public class Receipt {
        
        // constructor
        public Receipt() {
            decTotalAmountPaid = 0;
            decTotalAmountToPay = 0;
        }
        
        public ID contactId { get; set; }
        public String strContactName { get; set; }
        public String strContactFirstName { get; set; }     
        public ID auctionId { get; set; }
        public Date dtAuction { get; set; }
        public Decimal decTotalAmountPaid { get; set; }
        public Decimal decTotalAmountToPay { get; set; }
        public list<AUC_PurchaseOpportunity> listOppAuctionPurchases { get; set; }
    }

    // action method called by page whenever a paynow checkbox is changed.
    // recalc totals to pay.
    
    public PageReference ChangePayNow() {
    for(receipt r:listreceipts)
        strSaveResults = null;
        RecalcTotalAmountToPay(listReceipts); 
        fOppsToUpdate = true;
        return null;                
    }
    
    // parameter for ChangePayNow action method, set by page
    public ID oppIdChecked { get; set; }
    
    // utility to find a specific PO in listReceipts
    public AUC_PurchaseOpportunity POFromOppId(ID oppId) {
        for (Receipt r : listReceipts) {
            for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
                if (po.opp.Id == oppId) return po;
            }
        }
        return null;
    }

    // public method to update all checked opportunities to 
    // the paid StageName, and to update Payment Method and potentially Check Number on
    // either custom fields (specified in AuctionSettigns), or on the Payment Object of the NPSP.
    public PageReference UpdateCheckedOpps() {
        strSaveResults = null;
        if (CountCheckOpps(listReceipts) == 0) {
            strSaveResults = 'You must Check off which Opportunities to update.';
            return null;
        }
        
        fShowPanelCreditCard = false;
        
        list<Opportunity> listOppToUpdate = new list<Opportunity>();
        for (Receipt r : listReceipts) {
            for (AUC_PurchaseOpportunity po : r.listOppAuctionPurchases) {
                if (po.IsPayNow) {
                    po.opp.StageName = AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE;
                    listOppToUpdate.add(po.opp);
                    po.IsPayNow = false;
                    if (AUC_AuctionConstants.strOppPaymentMethodField != null) {
                        po.opp.put(AUC_AuctionConstants.strOppPaymentMethodField, strPaymentMethod);
                    }
                    if (AUC_AuctionConstants.strOppCheckNumberField != null && strPaymentMethod == 'Check') {
                        po.opp.put(AUC_AuctionConstants.strOppCheckNumberField, strCheckNumber);
                    }                   
                }
            }
        }
        
        // save the new stages
        update listOppToUpdate;
        
        // if using NPSP Payments, update payment info.
        AUC_AuctionMaintenance.UpdateNPSPPayments(listOppToUpdate, strPaymentMethod, strCheckNumber);
        
        // force the totals to recalc
        //RecalcTotalAmountToPay(listReceipts);
        // now force full reload to get all Opp fields updated
        listReceipts = null;    
        
        // clear our flag
        fOppsToUpdate = false;
        return null;
    }

    // public method for the Next Guest button.  
    // clear out guest, and refresh the page.
    public PageReference NextGuest() {
        contactIdPurchaser = null;
        // force IE into Standards Mode
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');             
        return null;
    }
        
    // public method for the Close button.  
    // use retURL if we have it, otherwise go to tickets tab.
    public PageReference Close() {
        string retURL = ApexPages.currentPage().getParameters().get('retURL');
        if (retURL == null || retURL == '') {
            retURL = '/apex/AuctionPurchases';
        }
        PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
    }
    
    // public property of the total amount checked off to pay.
    public decimal decTotalAmountToPay {
        get {
            if (listReceipts != null && listReceipts.size() > 0) {
                return listReceipts[0].decTotalAmountToPay;
            } else {
                return 0;
            }           
        }
        private set;
    }
    
    public string strPaymentMethod { get; set; }
    public string strCheckNumber { get; set; }
    
    // public method called by the page when the Payment Method changes
    public PageReference ChangePaymentMethod() {
        // new value will be in strPaymentMethod
        fShowPanelCreditCard = false;
        /********C&P Code Start***********/
          if(contactIdPurchaser!=null){
                     Contact con = [select Name from Contact where Id = :contactIdPurchaser];
                     xmlpaymentMethod.NameOnCard=con.name;
                     }
         /********C&P Code End***********/
        return null;
    }
    
    // public property to get the commandButton URL
    // for the Charge Credit Card button.   
    public string strCreditCardChargeURL {
        get {
            if (strCreditCardChargeURL == null && contactIdPurchaser != null) {
                string str = AUC_AuctionConstants.StrCreditCardChargeURLFormula();
                if (str != null) {
                    // {0} = contactId
                    // {1} = auctionId
                    // {2} = amount     
                    // {3} = sessionId
                    // {4} = partner server url
                    // {5} = organizationId
                    list<string> listFormat = new list<string>();
                    listFormat.add(contactIdPurchaser);
                    listFormat.add(auctionId);
                    if (listReceipts.size() > 0) {
                        listFormat.add(string.valueOf(listReceipts[0].decTotalAmountToPay));
                    } else {
                        listFormat.add('0');
                    }
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
  
   public list<opportunity>  auctionopportunity;//Get the list of opportunites which are having paynow checkbox checked.
   map<string,boolean> opppaynowboolean=new map<string,boolean>(); //Put the opportunityid and paynow checkbox details>
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
    // the following two properties are set in the constructor by passed in page parameters,
    // so that this page can get the correct sessionId of the 'front-end' server that
    // Conga merge requires to use Salesforce reports as a data source!
    // Unfortunately, we still couldn't get the correct Session from parameters
    // to a Check Out web tab, so I have removed this functionality.
    // private string strApiSessionId { get; set; }
    // private string strApiPartnerServerURL { get; set; }
    // public property to get the commandButton URL
    // for the View button, to invoke the receipts page  
    public string strOpenReceiptURL {
        get {
         /*******
            string str = AUC_AuctionConstants.StrCheckOutReceiptsURLFormula();
            if (str != null) {
                // {0} = contactId
                // {1} = auctionId
                // {2} = amount     
                // {3} = sessionId
                // {4} = partner server url
                // {5} = organizationId
                
                // NOTE that Conga wants 15 character ID's not 18.
                
                list<string> listFormat = new list<string>();
                string strID = contactIdPurchaser;
                listFormat.add(strID.left(15));
                strID = auctionId;
                listFormat.add(strID.left(15));
                if (listReceipts.size() > 0) {
                    listFormat.add(string.valueOf(listReceipts[0].decTotalAmountToPay));
                } else {
                    listFormat.add('0');
                }
                // get the correct session Id that works with Conga.
                //listFormat.add(EncodingUtil.urlEncode(UserInfo.getSessionId(),'UTF-8'));
                listFormat.add(EncodingUtil.urlEncode(strApiSessionId,'UTF-8'));

                // use the partner server URL that works with Conga.                
                //string strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
                listFormat.add(EncodingUtil.urlEncode(strApiPartnerServerURL,'UTF-8'));                 
                
                // Conga won't use this, but in case a future use case comes up.
                listFormat.add(UserInfo.getOrganizationId());                   
                str = string.format(str, listFormat);   
                return str;     
            } else {    
        *********/
       
            {       
                return '/apex/AuctionReceipts' +
                    '?RenderFormat=pdf' +
                    '&auctionId=' + auctionId +
                    '&contactId=' + contactIdPurchaser +
                    '&IncludeTickets=true';
            }
        }
        private set;
    }
    
    // public property on whether to display the credit card panel
    public boolean fShowPanelCreditCard { get; set; }
    
    // public method to show the credit card panel
    public PageReference ShowPanelCreditCard() {
        fShowPanelCreditCard = true;
        strPaymentMethod = 'Credit Card';
        return null;
    }
     /***********C&P Code Start*************/
     /**********Display Account Numbers from Cnp settings*****************/
   public List<SelectOption> getCnPAccount() {   
            List<SelectOption> options = new List<SelectOption>();  
        if(paaspackage==true){
           string status='Active';
           cnpaccountlist=Database.Query('Select Id,Name,Cnp_paas__CnP_Account_Number__c,Cnp_paas__CnP_Account_GUID__c,Cnp_paas__Currency_Code__c  from Cnp_paas__CnP_API_Settings__c where Cnp_paas__CnP_Account_Status__c=\'' + status + '\' limit 1000');
           for(sObject ac:cnpaccountlist){
                  options.add(new SelectOption((string)ac.get('Cnp_paas__CnP_Account_Number__c'),(String)ac.get('Name')+' ('+(String)ac.get('Cnp_paas__CnP_Account_Number__c')+') '));
                  AccountIDToGuid.put((string)ac.get('Cnp_paas__CnP_Account_Number__c'),(string)ac.get('Cnp_paas__CnP_Account_GUID__c'));
                  options.sort();
               }
          }
      return options;
   }
/**************Method to send the data to Api*************/
public void process()
{
 /****All the nodes from PaaS Class initialization***/
              PaaS_Class.Order XmlOrder=new PaaS_Class.Order();
              PaaS_Class.BillingInformation Billing=new PaaS_Class.BillingInformation();
              PaaS_Class.BillingAddress BillingAddress=new PaaS_Class.BillingAddress();
              PaaS_Class.items itemlst = new PaaS_Class.items();
              PaaS_Class.cnpTransaction  xmltransaction=new PaaS_Class.cnpTransaction();
              PaaS_Class.Operation XmlOperation=new PaaS_Class.Operation();              
              list<PaaS_Class.items>  items = new list<PaaS_Class.items>();
              XmlAuthentication.AccountGuid =AccountIDToGuid.get(XmlAuthentication.AccountID);
              paymentform=false;
                /*******Operation Node Declarations from API **********/
              xmloperation.DeclineFraud = false;
              xmloperation.EnableRestriction = false;
              xmlstring.getOperation_node(XmlOperation);
                 /*******Order Node Declarations from API **********/
              XmlOrder.OrderMode = 'Production';
              xmlstring.getOrder_node(XmlOrder);
            /********Declaring Custom parameters for processing existing Contact ID (SalesforceContactID)**********/    
              list<Paas_Class.CustomParameters> TempList=new list<Paas_Class.CustomParameters>();
            xmlstring.CustomParameterType = 'CardHolder';
        if(contactIdPurchaser!= null){
                  Paas_Class.CustomParameters tempitem=new Paas_Class.CustomParameters();
                  tempitem.Field='SalesforceContactID';
                  tempitem.value=contactIdPurchaser;
                  TempList.add(tempitem);
                  xmlstring.setCustomFields_tran(TempList);
                  xmlstring.getTransactionCustomFields(xmlstring); 
            }
              /***********Date Splitting code to pass into ChargeDate dynamically ***********/
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
         
         /**************Get the contact details *********/
           list<contact> contactlist = [select Id,FirstName,LastName, Email, Phone, MailingCity, MailingState, MailingCountry,  MailingPostalCode, MailingStreet, otherState,otherstreet, otherCity, otherCountry, otherPostalCode from Contact where ID =:contactIdPurchaser];
            if(contactlist[0].FirstName!=null)
              Billing.BillingFirstName = contactlist[0].FirstName;
            if(contactlist[0].LastName!=null)
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
            if(contactlist[0].MailingCountry!=null){
              BillingAddress.BillingCountryCode=xmlstring.getCountryCode(contactlist[0].MailingCountry);
            }else{
              BillingAddress.BillingCountryCode= '840';
            }
            if(contactlist[0].Phone!=null)
              BillingAddress.BillingPhone = contactlist[0].Phone;
            xmlstring.getAuthentication_node(XmlAuthentication);
            xmlstring.getBillingAddress_node(BillingAddress);
            xmlstring.getBillingInformation_node(Billing);
            set<string> auctionitemids=new set<string>();
            set<string> opportunityids=new set<string>();
            /**************Creation of Opportunity from Auction checkout ********/
                for(opportunity opp:auctionopportunity){
                    auctionitemids.add(opp.Auction_Item_Purchased__c);
                    opportunityids.add(opp.id);
                  }
                  /*********Assigning Campaigns based on the above opportunity **********/
        map<string,string> campnamemap=new map<string,string>();
        map<string,string> campidmap=new map<string,string>();
        list<campaign> camplist=[select id,name from campaign where name!=null];
                  for(campaign cam:camplist){
                      campnamemap.put(cam.id,cam.name);
                    }
                  for(opportunity opps:auctionopportunity){
                      campidmap.put(opps.id,opps.campaignid);
                    }
             for(opportunity opps:auctionopportunity){
               if(opppaynowboolean.get(opps.id)==true){
               /*****IF Opportunity ID found in the URL updating Opportunity information to Items List ************/
                  itemlst  = new PaaS_Class.items();
                  if(opps.Auction_Item_Name__c!=null){
                     itemlst.ItemName =opps.Auction_Item_Name__c;
                  } else{
                    itemlst.ItemName =opps.name;
                  }
                  xmltransaction.TransactionType = 'Payment';
                  if(opps.Number_of_Tickets__c!=null ){
                   itemlst.UnitPrice =(opps.amount/integer.valueOf(opps.Number_of_Tickets__c)).setscale(2);
                   itemlst.Quantity = integer.valueOf(opps.Number_of_Tickets__c);
                   }else {
                    itemlst.UnitPrice =opps.amount;
                   }
                   itemlst.UnitTax = 0.0;
                   itemlst.UnitDiscount = 0.0;                  
                if(opps.Auction_Item_Purchased__r.Show_Tax_Deductible__c == 'Yes: Manual' ){
                if(opps.Auction_Item_Purchased__r.Total_Tax_Deductible__c != null  && opps.amount >= opps.Auction_Item_Purchased__r.Total_Tax_Deductible__c ){
                         /********Assign UnitDeductible when Show_Tax_Deductible__c is Manual ********/
                          itemlst.UnitDeductible = opps.Auction_Item_Purchased__r.Total_Tax_Deductible__c;
                    
                  }else {
                  itemlst.UnitDeductible = opps.amount;
                  }
                  }else if(opps.Auction_Item_Purchased__r.Show_Tax_Deductible__c == 'Yes: Bid-FMV'){
                       /********Calculate  UnitDeductible with FMV when Show_Tax_Deductible__c is  (Amount - FMV)********/
                      if(opps.Auction_Item_Purchased__r.Fair_Market_Value__c!=null){
                      if(opps.Amount >= opps.Auction_Item_Purchased__r.Fair_Market_Value__c){
                        itemlst.UnitDeductible = opps.amount - opps.Auction_Item_Purchased__r.Fair_Market_Value__c;
                        }else{
                         itemlst.UnitDeductible=0.0;
                        }
                        }
                    }else{
                         itemlst.UnitDeductible=0;
                       }
                    if(opps.Auction_Item_Purchased__r.Token_Value__c!=null ) {
                       if(opps.amount >= opps.Auction_Item_Purchased__r.Token_Value__c){
                        itemlst.UnitDeductible = opps.amount;
                        }
                        }
                   if(paaspackage==true){
                       if((decimal)opps.get('CnP_PaaS__Tax_deductible__c')!=null ){
                          if(opps.amount >=(decimal)opps.get('CnP_PaaS__Tax_deductible__c')){
                           if(opps.Number_of_Tickets__c!=0 ){
                                 itemlst.UnitDeductible = (decimal)opps.get('CnP_PaaS__Tax_deductible__c')/integer.valueOf(opps.Number_of_Tickets__c);
                              }else{
                               itemlst.UnitDeductible = (decimal)opps.get('CnP_PaaS__Tax_deductible__c');
                              }
                           }else{
                            if(opps.Number_of_Tickets__c!=0 ){
                                 itemlst.UnitDeductible = opps.amount/integer.valueOf(opps.Number_of_Tickets__c);
                              }else{
                               itemlst.UnitDeductible = opps.amount;
                              }
                           }
                       }
                       if(opps.get('CnP_PaaS__SKU__c')!=null && opps.get('CnP_PaaS__SKU__c')!=''){
                     itemlst.SKU = (string)opps.get('CnP_PaaS__SKU__c');
                     }
                     }
                     if(opps.Auction_Item_Purchased__r.sku__c!=null && opps.Auction_Item_Purchased__r.sku__c!=''){
                     itemlst.SKU = opps.Auction_Item_Purchased__r.sku__c;
                     }
                      
                     itemlst.CustomFieldParameters ='OpportunityID,'+opps.id+':';
                     itemlst.campaign =campnamemap.get(campidmap.get(opps.id));
                      items.add(itemlst);
                 }              
          }
    xmlstring.getitemslist_node(items);
     xmlstring.getreceipt_node(xmlReceipt);
    /*************Get Reference Transaction Details****************/
          if(ReferencePayment!=null || ReferencePayment!=''){
             if(paaspackage==true){
                list<sObject> dupquery  = Database.Query('select Id,name,cnp_paas__vaultGuid__c from cnp_paas__CnP_Transaction__c where id=:ReferencePayment limit 1');
                if(!dupquery.isEmpty()){
                  xmlpaymentmethod.vaultguid = (string)dupquery[0].get('cnp_paas__vaultGuid__c');
                  xmlpaymentmethod.Ordernumber =(string)dupquery[0].get('Name');
                 }
               }
            }
        xmlpaymentMethod.PaymentType=strPaymentMethod;
        xmlstring.getPaymentMethod_node(xmlPaymentMethod);
        xmlstring.getTransactionDetails_node(xmltransaction);
         /*********Generate Xml file***********/
        xmlstring.getgeneratexml(xmlstring);
         /************Send Xml file to the API***********/
        xmlstring.Send_Transaction_api(xmlstring.xmlfile); 
        hideform = false;
 } // Process End
 /***********Call back the C&P Account Number**************/
 public void AccountChange(){
        list<SelectOption> lst = getReferenceTrans(); 
        if(!lst.isEmpty()){
                strPaymentMethod='ReferenceTransaction';
         }else{
                 if(creditcardpayment==true){
                strPaymentMethod='CreditCard';
                if(contactIdPurchaser!=null){
                     Contact con = [select Name from Contact where Id = :contactIdPurchaser];
                     xmlpaymentMethod.NameOnCard=con.name;
                     }
                    }
         }
   }
public string strcustom {get;set;}
/*********Display Custom payment methods*************/
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
    List<SelectOption> options = new List<SelectOption>();
       if(paaspackage==true){
          list<AggregateResult> ResultSet1 = new list<AggregateResult>();
           string status='Active'; 
           string transresult= 'Authorized';
           string payment='eCheck';
            if((!xmlvalue.isEmpty() && (string)xmlvalue[0].get('cnp_paas__Account_Number__c') !=null)|| (xmlauthentication.AccountID!=null && xmlauthentication.AccountID!='')){
            // Getting data from API settings 
                  Cnpaccountlist=Database.Query('Select Id,Name,cnp_paas__CnP_Account_Number__c,cnp_paas__CnP_Account_GUID__c,cnp_paas__Currency_Code__c from cnp_paas__CnP_API_Settings__c where cnp_paas__CnP_Account_Status__c=\'' + status + '\' and cnp_paas__CnP_Account_Number__c=\''+XmlAuthentication.AccountID+'\' LIMIT 1');   
                     if(!Cnpaccountlist.isEmpty()){
                       //Querying the transactions which are paid by credit card
                      ResultSet= Database.Query('select MAX(cnp_paas__TransactionDate__c) tdate,cnp_paas__CreditCard4x4__c cardnum from cnp_paas__CnP_Transaction__c where cnp_paas__Contact__c=:contactIdPurchaser and cnp_paas__CnPAccountID__c='+decimal.valueOf(XmlAuthentication.AccountID)+' and cnp_paas__CreditCard4x4__c!=null and cnp_paas__Transaction_Result__c = \''+transresult+'\' GROUP BY cnp_paas__CreditCard4x4__c');
                       //Querying the transactions which are paid by eCheck Method
                      ResultSet1 = Database.Query('Select Max(cnp_paas__TransactionDate__c) tdate1,cnp_paas__Check_Number__c icnum from cnp_paas__CnP_Transaction__c where cnp_paas__Contact__c =:contactIdPurchaser and cnp_paas__CnPAccountID__c='+decimal.valueOf(XmlAuthentication.AccountID)+' and (cnp_paas__Invoice_Check_Number__c!=null or cnp_paas__Check_Number__c!=null) and cnp_paas__Transaction_Result__c = \''+transresult+'\' GROUP BY cnp_paas__Check_Number__c');
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
            list<sObject> dupquery  = Database.Query('select Id,name, cnp_paas__TransactionDate__c,cnp_paas__Name_On_card__c,cnp_paas__CreditCard4x4__c,cnp_paas__Credit_Card_Name__c,cnp_paas__Invoice_Check_Number__c,cnp_paas__Check_Number__c,cnp_paas__vaultGuid__c,cnp_paas__CardExpiration__c,cnp_paas__PaymentType__c,cnp_paas__Transaction_Result__c from cnp_paas__CnP_Transaction__c where cnp_paas__TransactionDate__c IN :transactiondate and cnp_paas__Contact__c =:contactIdPurchaser and cnp_paas__Transaction_Result__c =\''+transresult+'\'' );
            list<sObject> dupquery1  =Database.Query('select Id,name, cnp_paas__TransactionDate__c,cnp_paas__Name_On_card__c,cnp_paas__CreditCard4x4__c,cnp_paas__Credit_Card_Name__c,cnp_paas__Invoice_Check_Number__c,cnp_paas__Check_Number__c,cnp_paas__vaultGuid__c,cnp_paas__CardExpiration__c,cnp_paas__PaymentType__c,cnp_paas__Transaction_Result__c from cnp_paas__CnP_Transaction__c where cnp_paas__TransactionDate__c IN :transactiondate and cnp_paas__Contact__c =:contactIdPurchaser and cnp_paas__PaymentType__c=\''+payment+'\' and cnp_paas__Transaction_Result__c =\''+transresult+'\'');
            Map<DateTime,String> NameonCardMap = new Map<DateTime,String>();
            Map<DateTime,String> CardExpirationMap = new Map<DateTime,String>();
            Map<DateTime,String> CardNumberMap = new Map<DateTime,String>();
            Map<DateTime,string> echeckmap= new Map<DateTime,String>();
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
   /******** To get payments section again if Transaction Declined*******/
   public void Retry(){
       tryagain = true;
       paymentform=true;
       hideform = true;
       if(xmlpaymentMethod.PaymentType == 'CreditCard'){
           xmlpaymentMethod.CardNumber = null;
           xmlpaymentMethod.Cvv2 = null;
       }
       if(xmlpaymentMethod.PaymentType == 'Check'){
           xmlpaymentMethod.AccountNumber= null;
       } 
   }
/******C&P Code End****************/
}