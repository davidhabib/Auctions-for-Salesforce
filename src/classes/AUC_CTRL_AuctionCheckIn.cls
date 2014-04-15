// Written by David Habib, copyright (c) 2009-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class AUC_CTRL_AuctionCheckIn { 

    /********C&P Code start *********/
     public boolean purchaseresult{get;set;}//Check payments submitted to API
     public String selecttype { get; set; }//Check Payment Entry Mode
     public boolean paaspackage{get;set;} //Check C&P PaaS existance
     public boolean hideform{get;set;}
     public boolean tryagain {get;set;}
     /**********To get the C&P Transaction Information from C&P Transaction object**********/
     public String ReferencePayment { get; set; }
     public list<AggregateResult> getResultSet() {return ResultSet;}
     public void setResultSet(list<AggregateResult> ResultSet) {this.ResultSet= ResultSet; }
     list<AggregateResult> ResultSet;
     /**********Objects(C&P Settings & API Settings) variables declared to get the the C&P Settings information**********/
     public list<sObject> xmlvalue{get;set;}
     public list<sObject> Cnpaccountlist{get;set;} 
     public string strPaymentMethod { get; set; }//To get the Payment Type      
     /******To check Payment Types based on C&P Settings ***********/
     public boolean creditcardpayment{get;set;}
     public boolean echeckpayment{get;set;}
     public boolean popayment{get;set;}
     public boolean custompayment{get;set;}
     public boolean paymentform{set;get;}
     Map<String,String> AccountIDToGuid = new Map<String,String>{};//Get the AcountGuid based on Account Number
     /**************Variables declared to call API methods*************/
     public PaaS_Class.Authentication XmlAuthentication{get;set;}
     public PaaS_Class.PaymentMethod xmlPaymentMethod{get;set;}
     public PaaS_Class xmlstring {get;set;}
     public PaaS_Class.Receipt xmlReceipt{get;set;}
      /********C&P Code End *********/
      
     // constructor for the class 
     public AUC_CTRL_AuctionCheckIn() {
        paymentform=true;
        hideform = true;
        
        // force IE into Standards Mode
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
                
        // get the current auction we were invoked from, and find & set the appropriate campaign.
        // NOTE: we declared auctionId as a string to avoid getting a runtime error if null 
        // was set for the parameter, which cannot be assigned to type Id.
        String strAuctionId = AUC_AuctionMaintenance.StrEscape(ApexPages.currentPage().getParameters().get('auctionId'));
        
        // do any initialization which is not dependent on having an auctionId
        auctionMaintenance = new AUC_AuctionMaintenance();
        listSOAuctions = auctionMaintenance.listSOAuctions; 
                        
        // use auctionId passed in if there, else use latest auction.
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
        
         /***************C&P code start******/
         
        
         /************Check the existance of PaaS by querying with Namespace Prefix*************/
         List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
         paaspackage=false;
         /******Do Intialization of PaaS_class and and its inner classes*************/
         XmlAuthentication=new PaaS_Class.Authentication(); 
             xmlpaymentMethod = new PaaS_Class.PaymentMethod();
             xmlstring =new PaaS_Class();
             xmlReceipt=new PaaS_Class.Receipt();
         if(cls!= null && !cls.isempty()){
             paaspackage= true;
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
                 //C&P settings dont have any conditions, by default put the values as TRUE 
                 if((boolean)xmlvalue[0].get('cnp_paas__Payment_Credit_Card__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_eCheck__c') == false  && (boolean)xmlvalue[0].get('cnp_paas__Payment_Purchase_Order__c') == false && (boolean)xmlvalue[0].get('cnp_paas__Payment_Custom_Payment_Type__c') == false){
                        creditcardpayment = true;
                        echeckpayment = true;
                 } else{
                         //C&P settings values
                         creditcardpayment =(boolean)xmlvalue[0].get('cnp_Paas__Payment_Credit_Card__c');
                         echeckpayment = (boolean)xmlvalue[0].get('cnp_Paas__Payment_eCheck__c');
                     }
                     
                if((string)xmlvalue[0].get('cnp_paaS__Account_Number__c')!=null){
                       XmlAuthentication.AccountID = (string)xmlvalue[0].get('cnp_paaS__Account_Number__c');
                    }
                    
              } else {
                         creditcardpayment = true;
                         echeckpayment = true;
                     } 
        }
           /***************C&P code End******/
    }

    // private status string for reporting the results of saving.
    public String strSaveResults { get; set; } 
   // status string for reporting helpful instructions and the results of saving.
    public string strStatus {
        get {
                boolean fAttendee = contactIdAttendee != null && contactIdAttendee != '';
                boolean fCaptain = idCaptain != null && idCaptain != '';
                boolean fSearchAttendee = searchAttendee != null && searchAttendee != '';
                
                if (strSaveResults != null) {
                    strStatus = strSaveResults;
                } else if (!fAttendee && !fCaptain && !fSearchAttendee) {
                    strStatus = 'Enter the name of a guest to display their information.'; 
                } else if (!fAttendee && fSearchAttendee) {
                    strStatus = 'There is no contact in the database with that name.  Enter a new contact in the New Contact section.';
                } else if (fAttendee && !fCaptain) {
                    strStatus = null;
                    strStatus = 'Please enter a table captain.  Tables hosted by organizations are at the end of the list.';
                } else if (!fAttendee && fCaptain) {
                    strStatus = 'Select one of the guests from the Guest list below or enter a new contact to add to this Table Captain.';
                } else if (fAttendee && fCaptain) {
                    strStatus = null;
                    strStatus = 'Update the guest\'s information and click <b>Save & Check In Contact</b>.<br/>Save their credit card by clicking <b>Save Credit Card</b>.' + 
                        '<br/>If the guest needs to buy tickets, click on the <b>Add Ticket Purchase</b> checkbox.' + 
                        '<br/><br/>It is <b>recommended</b> that only one person per household provide credit card information and have a bid number.';
                }
                return strStatus;
            }
        private set;
    }
    
   public AUC_AuctionMaintenance auctionMaintenance;
        
    // the currently selected Auction
    public Id auctionId { get; set; } 
        
    // the list of Auctions to put in the Auction dropdown
    public list<SelectOption> listSOAuctions { get; set; }

    // callback when the user changes the current auction in the dropdown.
    public PageReference ChangeAuction() {
        // clear any previous save message
        strSaveResults = null;
        
        // clear out all state that is specific to the auction
        auctionMaintenance.auctionId = auctionId;

        // setting contactId's to null will null out their dependencies.
        contactIdAttendee = null;
        idCaptain = null;
        return null;
    }  

    // holds the currently selected Attendee contact
    // has to be a string to allow a null Id ('') to get returned from the page.
    public string contactIdAttendee { 
        get; 
        set {
            // first invalidate anything dependent on a change
            if (contactIdAttendee != value) {
                strNameAttendee = null;
                attendeeEdit = null;
                oppTicketAttendee = null;
                strCreditCardValidateURL = null;
                fShowPanelCreditCard = false;
            }
            contactIdAttendee = value;
            if (contactIdAttendee == '') contactIdAttendee = null; 
        }       
    }
    
    // holds the currently selected Attendee's name 
    public string strNameAttendee { 
        get {
            if (strNameAttendee == null && contactIdAttendee != null) {
                Contact con = [select Name from Contact where Id = :contactIdAttendee];
                strNameAttendee = con.Name;
            }
            return strNameAttendee;
        }
        private set;
    }
      
    // callback when the user changes the Attendee contact lookup.
    public PageReference ChangeAttendeeLookup() {
        // clear any previous save message
        strSaveResults = null;
        
        // the setter for contactIdAttendee will 
        // automatically invalidate any dependencies!

        // see if they already have a captain, and only update the current
        // captain if we've found a new one.
       ID id = idCaptainForcontactIdAttendee(contactIdAttendee);
        if (id != null) idCaptain = id;
        
        /*************if PaaS exists C&P Code start*************/
        if(paaspackage==true){
          if(contactIdAttendee !=null && contactIdAttendee !='')
             {
                 list<string> sfaccountlist = new list<string>();
                 /*******Dyanmic Query to get the Account number from Cnp Transaction Object***********/
                 list<sObject> contactlist =Database.Query('select Id,Name,CnP_PaaS__Contact__c,CnP_PaaS__vaultGuid__c,CnP_PaaS__CardExpiration__c,CnP_PaaS__TransactionDate__c,CnP_PaaS__CreditCard4x4__c,CnP_PaaS__Name_On_card__c,CnP_PaaS__Invoice_Check_Number__c,CnP_PaaS__CnPAccountID__c from CnP_PaaS__CnP_Transaction__c where CnP_PaaS__Contact__c = \'' + String.escapeSingleQuotes(contactIdAttendee)+ '\'');
            if(!contactlist.isEmpty())
               {
                    for(sObject trns:contactlist){
                    sfaccountlist.add(string.valueof(trns.get('CnP_PaaS__CnPAccountID__c')));
                    }
               }
              string status='Active';
               /*******Dynamic query to get the C&P Account number from C&P API Settings Object based on C&P Transaction object Account Numbers***********/
            Cnpaccountlist=Database.Query('Select Id,Name,Cnp_paas__CnP_Account_Number__c,Cnp_paas__CnP_Account_GUID__c,Cnp_paas__Currency_Code__c  from Cnp_paas__CnP_API_Settings__c where Cnp_paas__CnP_Account_Status__c=\'' +String.escapeSingleQuotes(status) + '\' and CnP_PaaS__CnP_Account_Number__c IN :sfaccountlist');
           if((!xmlvalue.isEmpty() && (string)xmlvalue[0].get('cnp_paas__Account_Number__c')!=null) || (!sfaccountlist.isEmpty())){
               if(!sfaccountlist.isEmpty()){
                  xmlauthentication.AccountID = sfaccountlist[0];
                }
           }
                      if(creditcardpayment==true){
                      strPaymentMethod='CreditCard';
                      xmlpaymentMethod.NameOnCard=StrNameAttendee;
                      }
                
           }  
        }          
        /*****************C&P Code End**************/          
             return null;
      }  
  
    
    // this parameter is used in scenarios where the page
    // needs us to search for an attendee before it could wait
    // for the return from its javascript remoting call to get data
    public string searchAttendee { get; set; }
    
    // callback when the user changes the Attendee contact lookup and submits too quick.
    public PageReference SearchAttendeeLookup() {
        if (searchAttendee != null && searchAttendee != '') {
            list<Contact> listCon = [select Id from Contact where Name = :searchAttendee];
            if (listCon.size() > 0) {
                contactIdAttendee = listCon[0].Id;
            } else {
                contactIdAttendee = null;
                strSaveResults = null;
                strNameAttendee = searchAttendee; // to keep displaying the text.
                return null;
            }
        } else {
            contactIdAttendee = null;   
            strNameAttendee = null;     
        }
        return ChangeAttendeeLookup();
    }

    // utility to find the Captain for an Attendee
    public ID idCaptainForcontactIdAttendee(ID idAttendee) {       

        // get the CampaignMember for the attendee
        list<CampaignMember> listCM = [select contactId, Auction_Ticket_OppId__c, Table_Captain__c from CampaignMember 
            where contactId = :idAttendee and campaignId = :auctionMaintenance.campaignIdAuctionAttendees ];
        if (listCM.size() > 0) {
            if (listCM[0].Table_Captain__c != null) {
                // if they have a table captain, use it
                return listCM[0].Table_Captain__c;
            } else {
                // otherwise return the ticket purchaser
                list<OpportunityContactRole> listOCR = [select contactId from OpportunityContactRole 
                        where IsPrimary=true and opportunityId = :listCM[0].Auction_Ticket_OppId__c];
                if (listOCR.size() > 0) {
                    return listOCR[0].contactId;
                } else {
                    // if we didn't find a OCR, it might be just an ticket bought by an Account.
                    list<Opportunity> listOpp = [select accountId from Opportunity where Id = :listCM[0].Auction_Ticket_OppId__c];
                    if (listOpp.size() > 0) {
                        return listOpp[0].accountId;
                    }
                }
            }
        }
        return null;
    }
    
    // holds the currently selected Captain.  
    // Note that this can be either a Contact ID or an Account ID
    // has to be a string to allow a null Id ('') to get returned from the page.
    public string idCaptain { 
        get; 
        set {
            // invalidate anything dependent on a change
            if (idCaptain != value) {
                strNameCaptain = null;
                listAttendees = null;
                listOppCaptain = null;
                cmCaptain = null;
                mapTicketOppIdAttendeesLeft = null;
            }
            idCaptain = value;          
            if (idCaptain == '') idCaptain = null;
                
            // set the current attendee's captain and table if their CM has is new.  
            if (attendeeEdit != null && attendeeEdit.cm != null && attendeeEdit.cm.Id == null) { 
                attendeeEdit.cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);                   
                if (cmCaptain != null) {
                    attendeeEdit.cm.Table_Name_Number__c = cmCaptain.Table_Name_Number__c;
                }
                // see if there is an available ticket for this guest
                // and use its Paid status.
                attendeeEdit.cm.Paid__c = PaidTicketAvailable();
            }                                        
        }
    }
    
    // private utility to check if the current Captain has a free ticket available
    // and whether it has been paid for.
    private boolean PaidTicketAvailable() { 
        integer iLast = listAttendees.size() - 1;
        if (iLast >= 0 && listAttendees[iLast].cm.contactId == null) {
            return listAttendees[iLast].cm.Paid__c;
        } else {
            return false;
        }       
    }
    
    // differentiates whether our table captain is a Contact or an Account
    public boolean IsCaptainContact {
        get {
            if (idCaptain == null || 
                AUC_AuctionConstants.getObjectTypeFromId(idCaptain) == Contact.sObjectType) {
                return true;
            } else
                return false;
        }
    }
    
    // holds the currently selected Captain's name  
    public string strNameCaptain { 
        get {
            if (strNameCaptain == null && idCaptain != null) {
                if (IsCaptainContact) {             
                    Contact con = [select Name from Contact where Id = :idCaptain];
                    strNameCaptain = con.Name;
                } else {
                    Account acc = [select Name from Account where Id = :idCaptain];
                    strNameCaptain = acc.Name;  
                }
            }
            return strNameCaptain;
        }
        private set;
    } 

    // callback when the user changes the Table Captain contact lookup.
    public PageReference ChangeCaptainLookup() {
        // clear any previous save message
        strSaveResults = null;
        // the setter for idCaptain will
        // invalidate anything dependent.
        return null;
    }  
    
    // the ticket opportunity(ies) for the currently selected Captain
    public list<Opportunity> listOppCaptain { 
        get {
            if (listOppCaptain == null) {
                listOppCaptain = new list<Opportunity>();
                
                if (auctionId == null) return listOppCaptain;
                    
                // if we have a table captain, look for their ticket first.
                if (idCaptain != null) {
                    if (IsCaptainContact) {
                        listOppCaptain = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount, StageName, IsWon 
                            from Opportunity 
                            where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
                                and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
                                and Id in (select OpportunityId from OpportunityContactRole where contactId = :idCaptain)];
                    } else {
                        listOppCaptain = [select Id, AccountId, CampaignId, Number_Of_Tickets__c, Amount, StageName
                            from Opportunity
                            where RecordTypeId = :AUC_auctionMaintenance.recordtypeIdAuctionTicket
                                and CampaignId = :auctionMaintenance.campaignIdAuctionTickets
                                and AccountId  = :idCaptain];
                    }
                    if (listOppCaptain.size() > 0) {
                        return listOppCaptain;
                    }                   
                }
                // if there is no ticket holder, create a new ticket opp.
                listOppCaptain.add(new Opportunity(
                    RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
                    CampaignId = auctionMaintenance.campaignIdAuctionTickets));
            } 
            return listOppCaptain;
        }
        private set;             
    }  
    
    // the campaign member for the currently selected Captain
    private CampaignMember cmCaptain { 
        get {
            if (cmCaptain == null && idCaptain != null) {
                // look for it in the attendees list.
                for (Attendee att : listAttendees) {
                    if (att.cm != null && att.cm.contactId == idCaptain) {
                        cmCaptain = att.cm;
                        return cmCaptain;
                    }
                }   
            }
            return cmCaptain;
        }
        set;
    }
    
    // flag to track whether to add a ticket purchase for the Attendee
    public boolean fAddTicketPurchase { get; set; }
    // the optional ticket opportunity for the current Attendee
    public Opportunity oppTicketAttendee {
        get {
            if (oppTicketAttendee == null) {
                
                // see if they already have a ticket opp.
                if (contactIdAttendee != null) {
                    string rtTicket = AUC_AuctionMaintenance.recordtypeIdAuctionTicket;
                    string cmpIdTickets = auctionMaintenance.campaignIdAuctionTickets;
                    
                    string strSoql = 'select Id';
                    for (string str : AUC_AuctionMaintenance.listStrFromFieldSet('Opportunity', 'AuctionCheckInFS')) {
                        strSoql += ', Opportunity.' + str;
                    }
                    strSoql += ', Opportunity.campaign.name' ;
                    strSoql += ' from OpportunityContactRole ' +
                    ' where IsPrimary=true and contactId = :contactIdAttendee and ' +
                        ' opportunity.RecordTypeId = :rtTicket and opportunity.campaignId = :cmpIdTickets';         
                
                    list<OpportunityContactRole> listOCR = database.query(strSoql);
                    if (listOCR.size() > 0) {
                        oppTicketAttendee = listOCR[0].Opportunity;
                    }
                }
                
                // if lookup failed, create a new opp.
                if (oppTicketAttendee == null) {
                    oppTicketAttendee = new Opportunity(
                        RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
                        CampaignId = auctionMaintenance.campaignIdAuctionTickets,
                        CloseDate = system.Today()
                    );
                }
            }
            return oppTicketAttendee;
        }
        private set;
    }

    // a map to track number of slots left for each ticket
    private map<ID, double> mapTicketOppIdAttendeesLeft { get; set; } 
        
    // the list of attendees.  Note that this list has to hold existing (previously saved), as well as new Campaign Members.
    public list<Attendee> listAttendees {
        get {
            if (listAttendees == null) {
                listAttendees = new list<Attendee>(); 
                mapTicketOppIdAttendeesLeft = new map<ID, double>();            
                
                // find any existing attendees on the captain's ticket(s)
                if (listOppCaptain.size() > 0) { 
                    set<ID> setTicketOppId = new set<ID>();
                    double numTickets = 0;
                    for (Opportunity opp : listOppCaptain) {
                        if (opp.Id != null) {
                            setTicketOppId.add(opp.Id);
                            numTickets += opp.Number_Of_Tickets__c == null ? 0 : opp.Number_Of_Tickets__c;  
                            mapTicketOppIdAttendeesLeft.put(opp.Id, opp.Number_Of_Tickets__c);
                        }                                           
                    }
                    
                    // load up their CM info.
                    string strSoql = 'select ' + String.escapeSingleQuotes(strCMFields) +
                        ' from CampaignMember' + 
                        ' where campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' and ' +
                            ' (Auction_Ticket_OppId__c in :setTicketOppId ';
                    if (IsCaptainContact && idCaptain != null) {
                        strSoql += ' or Table_Captain__c = :idCaptain ';
                    }
                    strSoql += ')';
                    
                    list<CampaignMember> listCM = Database.query(strSoql);
                        
                    // create a map so we can match CM's with Contacts
                    map<ID, CampaignMember> mapContactIdCM = new map<ID, CampaignMember>();
                    for (CampaignMember cm : listCM) {
                        mapContactIdCM.put(cm.contactId, cm);
                    }               

                    // load up their contact info.
                    set<ID> setKeys = mapContactIdCM.keySet();
                    list<Contact> listCon = Database.query('select ' + String.escapeSingleQuotes(strContactFields) + 
                        ' from Contact where Id in :setKeys' + 
                        ' order by Name');              
                
                    for (Contact con : listCon) {
                        listAttendees.add(new Attendee(mapContactIdCM.get(con.Id), con));
                    }
                                            
                    // add slots for people who specified this table captain, but aren't on the captain's ticket opp
                    for (CampaignMember cm : listCM) {
                        if (!setTicketOppId.contains(cm.Auction_Ticket_OppId__c)) {
                            numTickets++;
                        } else {
                            double cLeft = mapTicketOppIdAttendeesLeft.get(cm.Auction_Ticket_OppId__c);
                            mapTicketOppIdAttendeesLeft.put(cm.Auction_Ticket_OppId__c, cLeft - 1);
                        }
                    }
                    
                    // create new CampaignMembers for any additional attendees on this ticket                   
                    CampaignMember cmCaptain = mapContactIdCM.get(idCaptain);
                    for (integer i = listCon.size()+1; i <= numTickets; i++) {
                        CampaignMember cm = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);                       
                        cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
                        cm.Paid__c = (listOppCaptain[0].amount != null);
                        if (cmCaptain != null) {
                            cm.table_name_number__c = cmCaptain.Table_Name_Number__c;
                        }                       
                        Contact con = new Contact();
                        listAttendees.add(new Attendee(cm, con));
                    }
                }
            }
            return listAttendees;
        }

        private set;        
    }   

    // helper routine to return all Contact field names from the Field Set
    private string strContactFields {
        get {
            if (strContactFields == null) {
                strContactFields = AUC_AuctionMaintenance.strFieldNamesFromFieldSet('Contact', 'AuctionsCheckInFS');
                
                // make sure Name field that is used in Guests datatable is included.
                if (!strContactFields.contains(' Name,')) strContactFields += ', Name';
            }
            return strContactFields;
        }
        set;
    }
    
    // helper routine to return all CampaignMember field names from the Field Set
    // we could optimize this to use fieldset api, but the CM fields are used
    // in two places that may require different fields.  so its easiest to just load them all.
    private string strCMFields {
        get {
            if (strCMFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.CampaignMember.fields.getMap();
                list<string> listStrFields = new list<string>();
                listStrFields.addAll(mapS.keySet());  
                strCMFields = '';
                for (string str : listStrFields) {
                    strCMFields += str + ',';
                }       
                strCMFields = strCMFields.substring(0, strCMFields.length()-1);
            }
            return strCMFields;
        }
        set;
    }

    // an Attendee object to hold Contact and CampaignMember fields to support the editing pane
    public Attendee attendeeEdit { 
        get {
            if (attendeeEdit == null) {
                // see if we already have their info loaded
                attendeeEdit = attendeeFromId(contactIdAttendee);               
                // if not loaded (not a current Attendee), then look it up
                if (attendeeEdit == null) { 
                    Contact con = new Contact();                
                    CampaignMember cm = new CampaignMember(CampaignId=auctionMaintenance.campaignIdAuctionAttendees);
                    cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
                    cm.contactId = contactIdAttendee;
                    cm.Paid__c = PaidTicketAvailable();
                    if (cmCaptain != null) {
                        cm.table_name_number__c = cmCaptain.Table_Name_Number__c;
                    }
                    

                    if (contactIdAttendee != null) {
                        con = Database.Query('select ' + strContactFields + ' from Contact where Id = :contactIdAttendee');

                        // we still need to make sure they don't already have a CM.  only happens in a case where the CM
                        // is no longer attached to either a Ticket Opp or a Table Captain.
                        string strSoql = 'select ' + strCMFields +
                            ' from CampaignMember' + 
                            ' where campaignId = \'' + auctionMaintenance.campaignIdAuctionAttendees + '\' and ' +
                                ' contactId = :contactIdAttendee';
                        list<CampaignMember> listCM = Database.query(strSoql);
                        if (listCM.size() > 0) {
                            cm = listCM[0];
                            if (cm.Table_Captain__c == null) {
                                // go ahead and prefill the current table captain.
                                cm.Table_Captain__c = (IsCaptainContact ? idCaptain : null);
                            }
                        }
                    }
                    attendeeEdit = new Attendee(cm, con);
                }
            }
            return attendeeEdit; 
        }
        private set;
    }

    // find the Attendee for the given contactId.
    public Attendee attendeeFromId(ID cId) {
        if (cId == null) return null;
        for (Attendee att : listAttendees) {
            if (att.con.Id == cId) {
                return att;
            }
        }
        return null;
    }

    // utility to ensure the attendee campaign has a status of 'Checked In'
    // needed to support pre 3.15 Auctions.
    private void AllowCheckedInStatus() {
        ID cmpId = auctionMaintenance.campaignIdAuctionAttendees;
        if (cmpId != null) {
            list<CampaignMemberStatus> listCMS = [Select Id From CampaignMemberStatus WHERE Label = 'Checked In' and CampaignId = :cmpId];
            // if not found, let's add it.
            CampaignMemberStatus cms;
            if (listCMS.size() == 0) {
                cms = new CampaignMemberStatus(
                    Label = 'Checked In',
                    CampaignId = cmpId,
                    HasResponded = true,
                    SortOrder = 500
                );
                insert(cms);                        
            }
        }
    }
    
                    
    // save all modified data.  a complex process to handle both updates and inserts!
    public PageReference SaveAttendeeInfo() {
                 
        strSaveResults = 'Starting Save...';
        try {
            // bail out if we aren't set up.
            if (attendeeEdit == null || attendeeEdit.con == null) {
                strSaveResults = 'There is no guest selected to save.';
                return null;
            }
                            
            // Steps:
            //  1. create or update Contact
            //  2. create optional Ticket Opp
            //  3. create or update CampaignMember
            //  4. cleanup

            // 1. Create or Update the Attendee Contact.
            if (attendeeEdit.con.Id == null) {
                insert attendeeEdit.con;
            } else {
                update attendeeEdit.con;
            }
            // don't update contactIdAttendee, or it will clear attendeeEdit (and its CM)
            
            
            // 2. create/update optional Ticket
            if (fAddTicketPurchase) {           

                if (oppTicketAttendee.Id == null) {

                    // create the opp for the ticket purchase           
                    oppTicketAttendee.Name = auctionMaintenance.StrOppTicketName(null, attendeeEdit.con.Id);                       
                    oppTicketAttendee.Auction_Non_Deductible_Amount__c = AUC_AuctionMaintenance.TicketNonDeductibleAmountOfAuctionId(AuctionId) * 
                        oppTicketAttendee.Number_Of_Tickets__c;         
                    
                    // see if we are dealing with the NonProfit Starter Pack and it is using the 1-to-1 Account model.
                    // if so, we need to set the Opp's Account to make the rollups work.
                    if (AUC_AuctionConstants.fSetAccountOnNewAuctionOpps) {
                        Contact contact = [select Name, AccountId from Contact where Id=:attendeeEdit.con.Id];  
                        oppTicketAttendee.AccountId = contact.AccountId;
                    }
                                
                    insert oppTicketAttendee;
                    
                    // only create contact role if client's code didn't do it!
                    if (AUC_AuctionConstants.fCreateOppContactRoles(oppTicketAttendee.Id, attendeeEdit.con.Id)) {               
                        OpportunityContactRole ocr = new OpportunityContactRole();
                        ocr.OpportunityId = oppTicketAttendee.Id;
                        ocr.contactId = attendeeEdit.con.Id;
                        ocr.Role = AUC_AuctionConstants.OPP_GIFT_DONOR_ROLE;
                        ocr.IsPrimary = true;
                        insert ocr;
                    }
                } else {
                    update oppTicketAttendee;
                }
            }
            
            // 3. create or update CampaignMember
            if (attendeeEdit.cm.Id == null) {
                attendeeEdit.cm.campaignId = auctionMaintenance.campaignIdAuctionAttendees;
                attendeeEdit.cm.contactId = attendeeEdit.con.Id;
            }
            AllowCheckedInStatus();
            attendeeEdit.cm.Status = 'Checked In';
            if (fAddTicketPurchase) {
                attendeeEdit.cm.Paid__c = true;
                attendeeEdit.cm.Auction_Ticket_OppId__c = oppTicketAttendee.Id; 
            } else if (attendeeEdit.cm.Auction_Ticket_OppId__c == null) {
                // find which captain's ticket has room for this attendee
                for (Opportunity opp : listOppCaptain) {
                    if (mapTicketOppIdAttendeesLeft.get(opp.Id) > 0) {
                        attendeeEdit.cm.Auction_Ticket_OppId__c = opp.Id;
                        attendeeEdit.cm.Paid__c = (attendeeEdit.cm.Paid__c || opp.Amount != null);
                        mapTicketOppIdAttendeesLeft = null; // so it will refresh
                        break;
                    }
                }                               
            }
            if (attendeeEdit.cm.id == null) {
                insert attendeeEdit.cm;             
            } else {
                update attendeeEdit.cm;
            }                       
                    
            strSaveResults = 'The Guest has been saved and checked in.';
            
            // 4. save done, so clear our complete state
            listAttendees = null;   
            oppTicketAttendee = null;
            listOppCaptain = null;  
            fAddTicketPurchase = false;
            strNameAttendee = null;
            strNameCaptain = null;
            
            // when the page reloads, let's make sure we show the current attendee and (possibly new) captain.
            contactIdAttendee = attendeeEdit.con.Id;
            if (attendeeEdit.cm.Table_Captain__c != null) {
                idCaptain = attendeeEdit.cm.Table_Captain__c;
            }
            return null;    
                    
        } catch (Exception e) {
            strSaveResults = 'Error encountered while trying to save.  ';
            ApexPages.addMessages(e);            
            return null;
        }               
    }

    // public method for the Next Guest button.  
    // clear out guest, keep captain, and refresh the page.
    public PageReference NextGuest() {
        contactIdAttendee = null;
        // force IE into Standards Mode
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=Edge');
        return null;
    }

    // public method for the Close button.  
    // use retURL if we have it, otherwise go to tickets tab.
    public PageReference Close() {
        string retURL = ApexPages.currentPage().getParameters().get('retURL');
        if (retURL == null || retURL == '') {
            retURL = '/apex/AuctionTickets';
        }
        PageReference p = new PageReference(retURL);
        p.setRedirect(true);
        return p;
    }

    // public property to get the commandButton URL
    // for the Authorize Credit Card button.    
    public string strCreditCardValidateURL {
        get {
            if (strCreditCardValidateURL == null) {
                string str = AUC_AuctionConstants.StrCreditCardValidateURLFormula();
                if (str != null) {
                    // {0} = contactId
                    // {1} = auctionId
                    // {2} = amount     
                    // {3} = sessionId
                    // {4} = partner server url
                    // {5} = organizationId
                    list<string> listFormat = new list<string>();
                    listFormat.add(contactIdAttendee);
                    listFormat.add(auctionId);
                    listFormat.add('0');
                    listFormat.add(UserInfo.getSessionId());
                    string strServerURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/services/Soap/u/23.0/'+ UserInfo.getOrganizationId();
                    listFormat.add(strServerURL);                   
                    listFormat.add(UserInfo.getOrganizationId());                   
                    str = string.format(str, listFormat);           
                }
                strCreditCardValidateURL = str;
            }
            return strCreditCardValidateURL;
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

    // public property on whether to display the credit card panel
     public boolean fShowPanelCreditCard { get; set; }
     // public method to show the credit card panel
     public PageReference ShowPanelCreditCard() {
        fShowPanelCreditCard = true;
        /**********C&P Code ************/
         if(creditcardpayment==true){       
          strPaymentMethod='CreditCard';
          xmlpaymentMethod.NameOnCard=StrNameAttendee;
        }
         
        /**********C&P Code End************/
        return null;
    }
    public PageReference ChangePaymentMethod() {
        // new value will be in strPaymentMethod
        fShowPanelCreditCard = true;
        /********C&P Code Start***********/
        
        xmlpaymentMethod.NameOnCard=StrNameAttendee;
        
         /********C&P Code End***********/
        return null;
    }  
    
    /*******************************************************************************************************
    * @description Attendee Class is a helper class that holds a contact and their campaign member.
    ********************************************************************************************************/
    public class Attendee {
        
        // constructor
        public Attendee(CampaignMember cmT, Contact conT) {
            cm = cmT;
            con = conT;
        }
        
        public CampaignMember cm { get; set; }
        public Contact con { get; set; }        
    }
    

    /*******************************************************************************************************
    * @description Javascript Remoting method to return a list of Contacts, optionally filtered by strFilter.
    * Note that we've changed AuctionCheckIn to now use the version of this that looks at the Auction.
    * @param strFilter the substring to filter by 
    * @return list<Contact>, which will be turned into a Javascript collection.
    ********************************************************************************************************/
    @RemoteAction global static list<Contact> getListContacts(string strFilter) {
        strFilter = '%' + strFilter + '%';  
        list<Contact> listContacts = [select Id, Name, MailingStreet, MailingCity 
                from Contact where 
                Name like :strFilter 
                order by Name asc];                         
        return listContacts;
    }       
    
    /*******************************************************************************************************
    * @description Javascript Remoting method to return a list of Contacts, optionally filtered by strFilter.
    * To try to avoid loading too many contacts, first search those on the Attendees list.  If none found,
    * then search all contacts.
    * @param auctionId the Auction to filter by 
    * @param strFilter the substring to filter by 
    * @return list<Contact>, which will be turned into a Javascript collection.
    ********************************************************************************************************/
    @RemoteAction global static list<Contact> getListAttendees(string auctionId, string strFilter) {
        strFilter = '%' + strFilter + '%';  
        if (auctionId == null || auctionId == '') return null;
        AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
        auctionMaintenance.auctionId = auctionId;

        // first look for contacts where are on the Attendees campaign      
        list<Contact> listContacts = [select Id, Name, MailingStreet, MailingCity 
                from Contact where 
                Name like :strFilter 
                    and Id in (select contactId from CampaignMember where campaignId = :auctionMaintenance.campaignIdAuctionAttendees)
                order by Name asc];

        // if none found, then search all contacts
        if (listContacts.size() == 0) {
            listContacts = [select Id, Name, MailingStreet, MailingCity 
                from Contact where 
                Name like :strFilter 
                order by Name asc]; 
        }               
            
        return listContacts;
    }       

    /*******************************************************************************************************
    * @description Javascript Remoting method to return a list of Contacts and Accounts, who are ticket 
    * holders or table captains on the specified auction, optionally filtered by strFilter.
    * @param auctionId the Auction to filter by 
    * @param strFilter the substring to filter by 
    * @return list<SObject>, (Contacts and Accounts) which will be turned into a Javascript collection.
    ********************************************************************************************************/
    @RemoteAction global static list<SObject> getListCaptains(string auctionId, string strFilter) {
        strFilter = '%' + strFilter + '%';      

        if (auctionId == null || auctionId == '') return null;
        AUC_AuctionMaintenance auctionMaintenance = new AUC_AuctionMaintenance();
        auctionMaintenance.auctionId = auctionId;
        
        set<ID> setContactId = new set<ID>();
        set<ID> setOppId = new set<ID>();
        
        // get all the primary contacts for auction tickets
        for (list<OpportunityContactRole> listOCR : [select contactId, opportunityId from OpportunityContactRole 
            where IsPrimary=true and 
            (opportunity.campaignId=:auctionMaintenance.campaignIdAuctionTickets) and
            contact.Name like :strFilter]) {
            
            // use set to avoid dups
            for (OpportunityContactRole ocr : listOCR) {
                setContactId.add(ocr.contactId);
                setOppId.add(ocr.opportunityId);
            }
        }
        
        // get all the table captains
        for (list<CampaignMember> listCM : [select contactId, Table_Captain__c from CampaignMember 
            where campaignId = :auctionMaintenance.campaignIdAuctionAttendees and
            Table_Captain__r.Name like :strFilter]) {
            
            // use set to avoid dups
            for (CampaignMember cm : listCM) {
                setContactId.add(cm.Table_Captain__c);
            }
        }
        list<SObject> listContactCaptains = [select Id, Name from Contact where Id in :setContactId order by Name]; 
        
        // now add any Accounts that own tickets.
        // since we don't really want to include 1:1 accounts when dealing with NPSP,
        // nor do we want accounts that were listed on the opp if there still was an individual ticket purchaser,
        // we filter out opps that have primary contacts.
        set<ID> setAccId = new set<ID>();
        for (list<Opportunity> listOpp : [select accountId from Opportunity
            where campaignId=:auctionMaintenance.campaignIdAuctionTickets and
            account.Name like :strFilter and
            Id not in :setOppId]) {
            
            // use set to avoid dups
            for (Opportunity opp : listOpp) {
                setAccId.add(opp.accountId);
            }
        }
        list<SObject> listAccountCaptains = [select Id, Name from Account where Id in :setAccId order by Name];

        // add our list of contacts and accounts together
        list<SObject> listSobj = new list<SObject>();
        listSobj.addAll(listContactCaptains);
        listSobj.addAll(listAccountCaptains);   
        return listSobj; 
    } 
      /***********C&P Code Start*************/
      /**********Display Account Numbers from C&P API settings*****************/
      public List<SelectOption> getCnPAccount() {   
          List<SelectOption> options = new List<SelectOption>();  
          if(paaspackage==true){
             string status='Active';
             //Query the values from API Settings Object
             cnpaccountlist=Database.Query('Select Id,Name,Cnp_paas__CnP_Account_Number__c,Cnp_paas__CnP_Account_GUID__c,Cnp_paas__Currency_Code__c  from Cnp_paas__CnP_API_Settings__c where Cnp_paas__CnP_Account_Status__c=\'' + String.escapeSingleQuotes(status) + '\' limit 1000');
             for(sObject ac:cnpaccountlist){
                options.add(new SelectOption((string)ac.get('Cnp_paas__CnP_Account_Number__c'),(String)ac.get('Name')+' ('+(String)ac.get('Cnp_paas__CnP_Account_Number__c')+') '));
                AccountIDToGuid.put((string)ac.get('Cnp_paas__CnP_Account_Number__c'),(string)ac.get('Cnp_paas__CnP_Account_GUID__c'));
                options.sort();
             }  
          }   
          return options;
      }
  /********************** Method to send the data to Api********************/
    public void process(){
        
         
             
              PaaS_Class.Order XmlOrder=new PaaS_Class.Order();
              PaaS_Class.BillingInformation Billing=new PaaS_Class.BillingInformation();
              PaaS_Class.BillingAddress BillingAddress=new PaaS_Class.BillingAddress();
              PaaS_Class.items itemlst = new PaaS_Class.items();
              PaaS_Class.cnpTransaction  xmltransaction=new PaaS_Class.cnpTransaction();             
              PaaS_Class.Operation XmlOperation=new PaaS_Class.Operation();
              list<PaaS_Class.items>  items = new list<PaaS_Class.items>();
              paymentform=false;
         
              xmltransaction.ChargeDate=date.today().format();
              XmlAuthentication.AccountGuid =AccountIDToGuid.get(XmlAuthentication.AccountID);
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
              if(contactIdAttendee!= null){
                   Paas_Class.CustomParameters tempitem=new Paas_Class.CustomParameters();
                   tempitem.Field='SalesforceContactID';
                   tempitem.value=contactIdAttendee;
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
            xmlpaymentMethod.PaymentType=strPaymentMethod;
            /*************Get Reference Transaction Details****************/
               if(ReferencePayment!=null || ReferencePayment!=''){
                   if(paaspackage==true){
                       list<Sobject> dupquery  =database.query('select Id,name,cnp_paas__vaultGuid__c from cnp_paas__CnP_Transaction__c where id=:ReferencePayment limit 1');
                       if(!dupquery.isEmpty()){
                          xmlpaymentmethod.vaultguid = (string)dupquery[0].get('cnp_paas__vaultGuid__c');
                          xmlpaymentmethod.Ordernumber = (string)dupquery[0].get('Name');
                        }
                  }
             }
              xmlstring.getPaymentMethod_node(xmlPaymentMethod);
             /**************Get the contact details *********/
             if(contactIdAttendee!=null){
                 list<contact>  contactlist= [select Id,FirstName,LastName, Email, Phone, MailingCity, MailingState, MailingCountry,  MailingPostalCode, MailingStreet, otherState,otherstreet, otherCity, otherCountry, otherPostalCode from Contact where ID =:contactIdAttendee];
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
                 if(contactlist[0].Phone!=null)
                     BillingAddress.BillingPhone = contactlist[0].Phone;
                 if(contactlist[0].MailingCountry!=null){
                     BillingAddress.BillingCountryCode=xmlstring.getCountryCode(contactlist[0].MailingCountry);
                 }else{
                     BillingAddress.BillingCountryCode= '840';
                }
            }else {
               if(attendeeEdit.con.firstname!=null)
                   Billing.BillingFirstName = attendeeEdit.con.FirstName;
               if(attendeeEdit.con.LastName!=null)
                   Billing.BillingLastName = attendeeEdit.con.LastName;
              if(attendeeEdit.con.Email!=null)
                   Billing.BillingEmail = attendeeEdit.con.Email;
               if(attendeeEdit.con.MailingStreet!=null)
                   BillingAddress.BillingAddress1 = attendeeEdit.con.MailingStreet;
               if(attendeeEdit.con.MailingCity!=null)
                   BillingAddress.BillingCity = attendeeEdit.con.MailingCity;
               if(attendeeEdit.con.MailingState!=null)
                   BillingAddress.BillingStateProvince = attendeeEdit.con.MailingState;
               if(attendeeEdit.con.MailingPostalCode!=null)
                   BillingAddress.BillingPostalCode = attendeeEdit.con.MailingPostalCode;
               if(attendeeEdit.con.Phone!=null)
                   BillingAddress.BillingPhone = attendeeEdit.con.Phone;
               if(attendeeEdit.con.MailingCountry!=null){
                   BillingAddress.BillingCountryCode=xmlstring.getCountryCode(attendeeEdit.con.MailingCountry);
               }else{
                   BillingAddress.BillingCountryCode= '840';
               }
            }
                 xmlstring.getAuthentication_node(XmlAuthentication);
                 xmlstring.getBillingAddress_node(BillingAddress);
                 xmlstring.getBillingInformation_node(Billing);
                 /*********Pre-Authorization: Passing 0$ Transaction/Opportunity only to save Credit Card Details in Salesforce. ************/
                 itemlst  = new PaaS_Class.items();
                   itemlst.ItemName = 'Auction Pre-Authorization';
                   itemlst.Quantity =1;
                   itemlst.UnitPrice = 0.0;
                   itemlst.UnitTax = 0.0;
                   itemlst.UnitDiscount = 0.0;
                   itemlst.UnitDeductible = 0.0;
                   xmltransaction.TransactionType = 'PreAuthorization'; 
                   items.add(itemlst);
                 xmlstring.getitemslist_node(items);                
                 xmlstring.getreceipt_node(xmlReceipt); 
                 xmlstring.getTransactionDetails_node(xmltransaction);
                 /*********Generate Xml file***********/
                 xmlstring.getgeneratexml(xmlstring);
                 /******Sending total values to API ************/
                 xmlstring.Send_Transaction_api(xmlstring.xmlfile); 
    purchaseresult=true; 
    hideform = false;
   }// Process End
    
    /***********Call back the Cnp Account Number**************/
    public void AccountChange(){
    if(paaspackage==true){
     if(creditcardpayment==true){
           strPaymentMethod='CreditCard';
           xmlpaymentMethod.NameOnCard=StrNameAttendee;
           }
         }
    }
    public string strcustom {get;set;}
    
    /*********Display Custom Payment methods*************/
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
   /***************C&P Code End*****************/
}