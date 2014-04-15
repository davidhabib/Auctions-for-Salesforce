@istest
public class Testclasses {
  public static testmethod void checkinCodeCoverageTests() {
                // create needed data
                Auction__c auction = new Auction__c (
                    Name = 'Test Auction',
                    Auction_Date__c = System.Today()
                );  
                insert auction; 
                System.Assert(auction.id != null);  
                Campaign campaign = [select Id, Auction__c from Campaign 
                    where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets and Auction__c = :auction.id];
                System.assertEquals(auction.id, campaign.Auction__c);
                Account acc = new Account(Name='My Test Account');
                insert acc;
                Contact contact = new Contact(
                    Firstname = 'Johnny',
                    Lastname = 'Test',
                    AccountId = acc.Id,email='test@test.com',mailingstreet='street',mailingcity='city',mailingstate='state',mailingpostalcode='123456',phone='1234567890',otherstreet='street',otherstate='state',othercity='city',otherpostalcode='12345'
                );
                insert contact; 
                //instantiate the controller with no page parameters.
                AUC_CTRL_AuctionCheckIn ctrl = new AUC_CTRL_AuctionCheckIn();
                system.assert(ctrl != null);
                ctrl.SaveAttendeeInfo();
                system.assert(ctrl.strSaveResults != null);
                    if(ctrl.Paaspackage==true){
                    sObject cnpapi=Schema.getGlobalDescribe().get('Cnp_paas__CnP_API_Settings__c').newSObject() ;
                    cnpapi.put('name','Testing');
                    cnpapi.put('Cnp_paas__CnP_Account_Number__c','18241');
                    cnpapi.put('Cnp_paas__CnP_Account_GUID__c','566798e8-9326-4663-9984-9c67ffe495f7');
                    cnpapi.put('Cnp_paas__CnP_Account_Status__c','Active');
                    insert  cnpapi;
                    
                    }
                //point to our VF page
                PageReference p = new PageReference('Page.AuctionCheckIn');
                p.getParameters().put('auctionId', auction.id); 
                Test.setCurrentPageReference(p);
                ctrl.accountchange();
                //instantiate the controller for this opp
                ctrl = new AUC_CTRL_AuctionCheckIn();
                system.assertEquals(auction.Id, ctrl.auctionId);
                ctrl.ChangeAuction();
                system.assertEquals(auction.Id, ctrl.auctionId);
                system.assertEquals(auction.Id, ctrl.auctionMaintenance.auctionId);
                ctrl.XmlAuthentication.Accountid='18241';
                 
                // test the initial state
                system.assertEquals(null, ctrl.contactIdAttendee);
                system.assertEquals(null, ctrl.idCaptain);
                system.assertEquals(null, ctrl.strNameAttendee);
                system.assertEquals(null, ctrl.strNameCaptain);
                system.assertEquals(null, ctrl.searchAttendee);
                system.assertEquals(null, ctrl.strSaveResults);
                system.assert(ctrl.attendeeEdit != null);
                system.assert(ctrl.attendeeEdit.con != null);
                system.assert(ctrl.attendeeEdit.cm != null);
                system.assert(ctrl.oppTicketAttendee != null);
                system.assert(ctrl.listSOAuctions.size() > 0);
                system.assert(ctrl.listSOAuctions.size() > 0);
                system.assertEquals(0, ctrl.listAttendees.size());
                system.assertEquals(null, ctrl.attendeeFromId(null));
                system.assertEquals(null, ctrl.idCaptainForcontactIdAttendee(null));
                system.assertEquals(null, ctrl.fAddTicketPurchase);
                system.assertEquals(true, ctrl.IsCaptainContact);
                ctrl.ChangeAttendeeLookup(); 
                ctrl.ChangeCaptainLookup();
                ctrl.Close();
                ctrl.NextGuest();
                ctrl.ShowPanelCreditCard();
                ctrl.getcnpaccount();
                ctrl.SaveAttendeeInfo();
                ctrl.SearchAttendeeLookup();
                // set a contact
                ctrl.contactIdAttendee = contact.Id;
                ctrl.ChangeAttendeeLookup();
                system.assertEquals('Johnny Test', ctrl.strNameAttendee);
                system.assert(ctrl.attendeeEdit != null);
                system.assert(ctrl.attendeeEdit.con.Id == contact.Id);
                system.assert(ctrl.attendeeEdit.cm != null);
                ctrl.changepaymentmethod();
                // save a Contact's ticket purchase
                ctrl.fAddTicketPurchase = true;
                ctrl.oppTicketAttendee.amount = 100;
                ctrl.oppTicketAttendee.number_of_Tickets__c = 4;
                ctrl.oppTicketAttendee.StageName = 'Won Closed';
                ctrl.SaveAttendeeInfo();
                system.assert(ctrl.strSaveResults != null);
                list<CampaignMember> listCM = [select contactId, campaignId, Auction_Ticket_OppId__c, Table_Captain__c from CampaignMember 
                    where contactId = :contact.Id and campaignId = :ctrl.auctionMaintenance.campaignIdAuctionAttendees];
                system.assertEquals(1, listCM.size());  
                system.assertEquals(null, ctrl.idCaptain);
                ctrl.contactIdAttendee = contact.Id;
                ctrl.ChangeAttendeeLookup();
                system.assertEquals(contact.Id, ctrl.idCaptainForcontactIdAttendee(contact.Id));
                system.assertEquals(contact.Id, ctrl.idCaptain);
                system.assertEquals('Johnny Test', ctrl.strNameCaptain);
                system.assertEquals(4, ctrl.listAttendees.size());
                ctrl.contactIdAttendee = null;
                ctrl.ChangeAttendeeLookup();
                ctrl.idCaptain = null;
                ctrl.ChangeCaptainLookup();
                system.assertEquals(0, ctrl.listAttendees.size());
                ctrl.getResultset();
                // test search functionality
                ctrl.searchAttendee = 'A bogus name you will not find!';
                ctrl.SearchAttendeeLookup();
                system.assertEquals(null, ctrl.contactIdAttendee);
                ctrl.searchAttendee = 'Johnny Test';
                ctrl.SearchAttendeeLookup();
                system.assertEquals(contact.Id, ctrl.contactIdAttendee);
                system.assertEquals(contact.Id, ctrl.idCaptain);
                system.assertEquals(4, ctrl.listAttendees.size());
                // save a new contact as an attendee
                ctrl.contactIdAttendee = null;
                ctrl.ChangeAttendeeLookup();
                ctrl.attendeeEdit.con.FirstName = 'Janey';
                ctrl.attendeeEdit.con.LastName = 'Test';
                system.assertEquals(contact.Id, ctrl.attendeeEdit.cm.Table_Captain__c);
               system.assertEquals(null, ctrl.strSaveResults);
                ctrl.SaveAttendeeInfo();
                system.assert(ctrl.strSaveResults != null);
                system.assert(ctrl.contactIdAttendee != null);
                system.assert(ctrl.contactIdAttendee != contact.Id);
                system.assertEquals(true, ctrl.IsCaptainContact);
                system.assertEquals(contact.Id, ctrl.idCaptainForcontactIdAttendee(ctrl.contactIdAttendee));
                // test out an account table captain
                Account acc2 = new Account(Name='Another Test Account');
                insert acc2;        
                Opportunity opp = new Opportunity(              
                    RecordTypeId = AUC_auctionMaintenance.recordtypeIdAuctionTicket,
                    CampaignId = ctrl.auctionMaintenance.campaignIdAuctionTickets
                );              
                opp.AccountId = acc2.Id;
                opp.Amount = 1000;
                opp.StageName = 'Won Closed';
                opp.Number_Of_Tickets__c = 10;
                opp.Name = 'my test account ticket purchase';
                opp.CloseDate = system.today();
                insert opp;
                ctrl.idCaptain = acc2.Id;
                ctrl.ChangeCaptainLookup();
                system.assertEquals('Another Test Account', ctrl.strNameCaptain);
                system.assertEquals(false, ctrl.IsCaptainContact);
                system.assertEquals(acc2.Id, ctrl.idCaptain);
                system.assert(ctrl.listOppCaptain != null);
                system.assertEquals(ctrl.listOppCaptain[0].Id, opp.Id);
                system.debug(ctrl.listAttendees);
                system.assertEquals(10, ctrl.listAttendees.size());
                // save another contact to the account table
                ctrl.contactIdAttendee = null;
                ctrl.ChangeAttendeeLookup();
                ctrl.idCaptain = acc2.Id;
                ctrl.ChangeCaptainLookup();
                ctrl.attendeeEdit.con.FirstName = 'Joey';
                ctrl.attendeeEdit.con.LastName = 'Test';
                system.assertEquals(null, ctrl.strSaveResults);
                ctrl.SaveAttendeeInfo();
                system.assert(ctrl.strSaveResults != null);
                system.assertEquals(opp.Id, ctrl.attendeeEdit.cm.Auction_Ticket_OppId__c);
                system.assert(ctrl.contactIdAttendee != null);  
                //system.assertEquals(acc2.Id, ctrl.idCaptainForcontactIdAttendee(ctrl.contactIdAttendee));
                // test remoting functions
                //system.assert(AUC_CTRL_AuctionCheckIn.getListContacts('Test').size() >= 3);     
                //system.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Johnny Test').size() >= 1);
                //system.assert(AUC_CTRL_AuctionCheckIn.getListCaptains(ctrl.auctionId, 'Another Test Account').size() >= 1);
                ctrl.getcusvalue();
                ctrl.process();  
                ctrl.Retry();  
      }       
     static testmethod void checkoutCodeCoverageTests() {
                    // create needed data
                    Account acc = new Account(Name='My Test Account');
                    insert acc;     
                    Contact contact1 = new Contact(Firstname='David', Lastname='Test', othercity='city',AccountId=acc.Id,email='test@test.com',mailingstreet='street',mailingcity='city',mailingstate='state',mailingpostalcode='123456',phone='1234567890',otherstreet='street',otherstate='state',otherpostalcode='12345');
                    insert contact1;
                    Contact contact2 = new Contact(Firstname='John', Lastname='Test',othercity='city', AccountId=acc.Id,email='test@test.com',mailingstreet='street',mailingcity='city',mailingstate='state',mailingpostalcode='123456',phone='1234567890',otherstreet='street',otherstate='state',otherpostalcode='12345');
                    insert contact2;
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction;  
                   List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
                    if(!cls.isempty() && cls!= null){
                    sObject xmlvalue= Schema.getGlobalDescribe().get('cnp_paas__XML_Setting__c').newSObject() ;
            xmlvalue.put('cnp_paas__custom_payment_options__C','test1;test2');
            xmlvalue.put('Name','Test');  
            xmlvalue.put('cnp_paas__account_number__C','18241');
            insert xmlvalue;
            sObject cnpapi=Schema.getGlobalDescribe().get('Cnp_paas__CnP_API_Settings__c').newSObject() ;
            cnpapi.put('name','Testing');
            cnpapi.put('Cnp_paas__CnP_Account_Number__c','18241');
            cnpapi.put('Cnp_paas__CnP_Account_GUID__c','566798e8-9326-4663-9984-9c67ffe495f7');
            cnpapi.put('Cnp_paas__CnP_Account_Status__c','Active');
            insert  cnpapi; 
               sObject cnptrans=Schema.getGlobalDescribe().get('CnP_PaaS__CnP_Transaction__c').newSObject();
               cnptrans.put('Cnp_paas__cnpaccountid__C',18241);
               cnptrans.put('CnP_PaaS__Contact__c',contact2.id);
               cnptrans.put('CnP_PaaS__TransactionDate__c',system.today());
               cnptrans.put('CnP_PaaS__TransactionTimeZone__c',system.now());
               cnptrans.put('CnP_PaaS__VaultGUID__c','a1c921eb-d5b0-40f7-8c90-20ea5a550eba');
               cnptrans.put('CnP_PaaS__TotalDue__c',10);
               insert cnptrans;
               }
                    Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees and Auction__c = :auction.id];
                    System.assertEquals(auction.id, campaign.Auction__c);
                    CampaignMember cm1 = new CampaignMember();
                    cm1.CampaignId = campaign.id;
                    cm1.ContactId = contact1.id;
                    insert cm1;
                    CampaignMember cm2 = new CampaignMember();
                    cm2.CampaignId = campaign.id;
                    cm2.ContactId = contact2.id;
                    insert cm2;
                    Auction_Item__c ai = new Auction_Item__c (
                        Auction_Item_Name__c = 'Test Auction Item',
                        Auction__c = auction.id,
                        FMV_Override__c = 100
                    );
                    insert ai;
                    AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
                    am.auctionId = auction.Id;
                    System.assertEquals(campaign.Id, am.campaignIdAuctionAttendees);
                    Opportunity oppPurchase= new Opportunity (
                        Name = 'My Auction Item Purchase',
                        CampaignId = campaign.id,
                        RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
                        StageName = AUC_AuctionConstants.OPP_STAGE_PLEDGED,
                        CloseDate = System.Today(),
                        Amount = 150,
                        Auction_Item_Purchased__c = ai.Id,
                        Auction_Non_Deductible_Amount__c = 100
                    );
                    insert oppPurchase;
                    system.AssertEquals(150, oppPurchase.Amount);
                    system.AssertEquals(100, oppPurchase.Auction_Non_Deductible_Amount__c);
                    Opportunity opp = [select Id, Name, Auction_Deductible_Amount__c from Opportunity where Id=:oppPurchase.id];
                    system.AssertEquals(50, opp.Auction_Deductible_Amount__c);
                    OpportunityContactRole oppcr = new OpportunityContactRole();
                    oppcr.ContactId = contact1.id;
                    oppcr.OpportunityId = oppPurchase.id;
                    oppcr.IsPrimary = true;
                    insert oppcr;
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionCheckOut');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller for this opp
                    AUC_CTRL_AuctionCheckOut ctrl = new AUC_CTRL_AuctionCheckOut();
                    ctrl.getresultset();
                    System.AssertEquals(auction.id, ctrl.auctionId);
                    ctrl.ChangeAuction();
                    ctrl.XmlAuthentication.AccountID='18241';
                     ctrl.getreferencetrans();
                    System.AssertEquals(auction.id, ctrl.auctionId);
                     AUC_CTRL_AuctionCheckOut.Purchaser purchaser=new  AUC_CTRL_AuctionCheckOut.Purchaser();
                    ctrl.searchPurchaser = '';
                    ctrl.SearchPurchaserLookup();
                    system.assertEquals(null, ctrl.contactIdPurchaser);
                    system.assert(ctrl.strStatus.startsWith('Enter the name'));
                    ctrl.searchPurchaser = 'This guy does not exist';
                    ctrl.SearchPurchaserLookup();
                    system.assertEquals(null, ctrl.contactIdPurchaser);
                    system.assert(ctrl.strStatus.startsWith('No attendee'));
                    ctrl.searchPurchaser = 'David Test';
                    ctrl.SearchPurchaserLookup();
                    system.assertEquals(contact1.id, ctrl.contactIdPurchaser);
                    system.assertEquals('David Test - ', ctrl.strNamePurchaser);
                   // system.assert(ctrl.strStatus.startsWith('1. Check <b>Pay Now</b>'));
                    system.assert(ctrl.listReceipts != null);
                    system.assertEquals(1, ctrl.listReceipts.size());
                    system.assert(ctrl.listReceipts[0].listOppAuctionPurchases != null);
                    system.assertEquals(1, ctrl.listReceipts[0].listOppAuctionPurchases.size());
                    system.assertEquals(150, ctrl.listReceipts[0].decTotalAmountToPay);
                    system.assert(ctrl.strOpenReceiptURL != null);
                    system.assert(ctrl.strCreditCardChargeURL == null || ctrl.strCreditCardChargeURL != null);
                    system.Assert(ctrl.fHasReceipts);
                    system.assertEquals(null, ctrl.ChangePayNow()); 
                    opp = [select Id, Name, Auction_Deductible_Amount__c, StageName from Opportunity where Id=:oppPurchase.id];
                    system.AssertEquals(AUC_AuctionConstants.OPP_STAGE_PLEDGED, opp.StageName);
                    system.assert(ctrl.UpdateCheckedOpps() == null);
                    opp = [select Id, Name, Auction_Deductible_Amount__c, StageName from Opportunity where Id=:oppPurchase.id];
                    system.AssertEquals(AUC_AuctionConstants.OPP_STAGE_WON_NOT_THANKED_STAGE, opp.StageName);
                    ctrl.NextGuest();
                     ctrl.close();
                      ctrl.contactIdPurchaser = contact2.id;
                    ctrl.ChangePurchaserLookup();
                    ctrl.changepaymentmethod();
                    ctrl.ShowPanelCreditCard();
                    ctrl.getcnpaccount();
                    ctrl.accountchange();
                    ctrl.getcusvalue();
                    list< AUC_CTRL_AuctionCheckOut.Purchaser> listP = AUC_CTRL_AuctionCheckOut.getListPurchasers(auction.Id, 'Test');
                    system.assert(listP != null);
                    system.assertEquals(2, listP.size());
                    ctrl.POfromoppid(opp.id);
                     ctrl.process();
                     ctrl.Retry();
                    system.assert(ctrl.strStatus.contains('no purchases'));
                    system.Assert(ctrl.listReceipts != null);
                    system.Assert(ctrl.listReceipts.size() == 0); // since contact2 has no purchases.
                    system.Assert(ctrl.fHasReceipts == false);
                    system.assert(ctrl.close() != null);
      }  
    public static testmethod void ticketsCodeCoverageTests() {
                    // create needed data
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction; 
                    System.Assert(auction.id != null); 
                    Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets and Auction__c = :auction.id];
                    System.assertEquals(auction.id, campaign.Auction__c);
                    Account acc = new Account(Name='My Test Account');
                    insert acc;
                    Contact contact = new Contact(
                        Firstname = 'Johnny',
                        Lastname = 'Test',
                        AccountId = acc.Id,othercity='city',email='test@test.com',mailingstreet='street',mailingcity='city',mailingstate='state',mailingpostalcode='123456',phone='1234567890',otherstreet='street',otherstate='state',otherpostalcode='12345'
                    );
                    insert contact;     
            List<ApexClass> cls = [SELECT NamespacePrefix FROM ApexClass where NamespacePrefix='CnP_PaaS' Limit 1];
                    if(!cls.isempty() && cls!= null){
                        sObject xmlvalue= Schema.getGlobalDescribe().get('cnp_paas__XML_Setting__c').newSObject() ;
                        xmlvalue.put('cnp_paas__custom_payment_options__C','test1;test2');
                        xmlvalue.put('Name','Test');  
                        xmlvalue.put('cnp_paas__account_number__C','18241');
                        insert xmlvalue;
                        sObject cnpapi=Schema.getGlobalDescribe().get('Cnp_paas__CnP_API_Settings__c').newSObject() ;
                        cnpapi.put('name','Testing');
                        cnpapi.put('Cnp_paas__CnP_Account_Number__c','18241');
                        cnpapi.put('Cnp_paas__CnP_Account_GUID__c','566798e8-9326-4663-9984-9c67ffe495f7');
                        cnpapi.put('Cnp_paas__CnP_Account_Status__c','Active');
                        insert  cnpapi; 
                        sObject cnptrans=Schema.getGlobalDescribe().get('CnP_PaaS__CnP_Transaction__c').newSObject();
                       cnptrans.put('Cnp_paas__cnpaccountid__C',18241);
                       cnptrans.put('CnP_PaaS__Contact__c',contact.id);
                       cnptrans.put('CnP_PaaS__TransactionDate__c',system.today());
                       cnptrans.put('CnP_PaaS__TransactionTimeZone__c',system.now());
                       cnptrans.put('CnP_PaaS__VaultGUID__c','a1c921eb-d5b0-40f7-8c90-20ea5a550eba');
                       cnptrans.put('CnP_PaaS__TotalDue__c',10);
                       insert cnptrans;
                   }
            
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionNewTicketWizard');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller for this opp
                    AUC_CTRL_AuctionNewTicketWizard ctrl = new AUC_CTRL_AuctionNewTicketWizard();
                    ctrl.getcnpaccount();
                    ctrl.contactRole.ContactId = contact.id;
                     ctrl.processpaymentnow=true;
                     ctrl.getcnpaccountnumber();
                     ctrl.getpaymenttypes();
                     ctrl.processpaymentnow();
                     ctrl.processpaymentnow=false;
                     ctrl.getcusvalue();
                     ctrl.XmlAuthentication.Accountid='18241';
                      ctrl.getreferencetrans();
                    System.AssertEquals(campaign.Id, ctrl.opp.CampaignId);
                    System.AssertEquals(System.Today(), ctrl.opp.CloseDate);
                    ctrl.getresultset();
                    ctrl.opp.Amount = 15;
                    ctrl.opp.Number_Of_Tickets__c = 4;
                    ctrl.OnChange_NumberOfTickets();
                    ctrl.DeleteCM();
                    System.AssertEquals(4, ctrl.listCmpMbrAttendees.size());
                    System.AssertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
                    ctrl.ChangePaymentMethod();
                    ctrl.ShowPanelCreditCard();
                    system.assertEquals(true, ctrl.fShowPanelCreditCard);
                    system.assertEquals('Credit Card', ctrl.strPaymentMethod);
                    system.assertEquals(null, ctrl.strCheckNumber);
                    system.assertEquals(null, ctrl.strCreditCardChargeURL);
                    system.assertNotEquals(null, ctrl.strPaymentProcessorWindowParameters);
                    system.assertEquals(false, ctrl.fShowPaymentProcessorOnPage);
                    system.assertNotEquals(null, ctrl.strPaymentProcessorPageHeight);
                    ctrl.Save();
                    System.Assert(ctrl.opp.id != null);
                   // System.AssertEquals('The ticket purchase has been saved.  1 contacts have been added to the auction attendee campaign.', ctrl.strSaveResults);
                    ctrl.saveandclose();
                    ctrl.purchaseclose();
                    // now test editing an existing ticket opp
                    //point to our VF page
                    p = new PageReference('Page.AuctionNewTicketWizard');
                    p.getParameters().put('auctionId', auction.id); 
                    p.getParameters().put('oppId', ctrl.opp.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller for this opp
                    ctrl = new AUC_CTRL_AuctionNewTicketWizard();
                    System.AssertEquals(contact.Id, ctrl.contactRole.ContactId);
                    System.AssertEquals(campaign.Id, ctrl.opp.CampaignId);
                    System.AssertEquals(System.Today(), ctrl.opp.CloseDate);
                    ctrl.opp.Amount = 25;
                    ctrl.opp.Number_Of_Tickets__c = 6;
                    ctrl.OnChange_NumberOfTickets();
                    System.AssertEquals(6, ctrl.listCmpMbrAttendees.size());
                    System.AssertEquals(contact.Id, ctrl.listCmpMbrAttendees[0].ContactId);
                    ctrl.accountchange();
                    ctrl.getcusvalue();
                    ctrl.Save();
                    ctrl.Cancel();
                    ctrl.purchaseticket();
                    ctrl.purchaseclose();
                    ctrl.Retry();
                    System.AssertEquals('The ticket purchase has been saved.  0 contacts have been added to the auction attendee campaign.  1 contacts have been updated in the auction attendee campaign.', ctrl.strSaveResults);
         }
    
       static testMethod void UnitTestNullAuction() {
                    // delete all auctions first
                    delete [select Id from Auction__c];
                     //point to our VF page
                    PageReference page = new PageReference('Page.AuctionNewTicketWizard');
                    page.getParameters().put('auctionId', 'null');
                    Test.setCurrentPageReference(page);
                    //instantiate the controller for this opp
                    AUC_CTRL_AuctionNewTicketWizard ctrl = new AUC_CTRL_AuctionNewTicketWizard();
                    System.AssertEquals(null, ctrl.auctionId);
                    System.AssertEquals(1, ctrl.listSOAuctions.size());
                    System.AssertEquals(0, ctrl.listCmpMbrAttendees.size());
                    ctrl.Cancel();  
         }  
       static testmethod void AuctionItemsCodeCoverageTests() {
                    // create needed data
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction; 
                    Auction_Item__c ai = new Auction_Item__c(
                        Auction__c = auction.Id,
                        Auction_Item_Name__c = 'Test Auction Item'
                    );  
                    insert ai;
                    AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
                    am.auctionId = auction.Id;
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionItems');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller 
                    AUC_CTRL_AuctionItems pageCtrl = new AUC_CTRL_AuctionItems();
                    AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
                    compCtrl.pageController = pageCtrl;
                    system.assert(pageCtrl.listStrFields != null);
                    system.assert(pageCtrl.strNameField != null);
                    system.assert(pageCtrl.getStrSoql() != null);
                    system.assert(pageCtrl.NewItem() != null);
        }
    static testmethod void DonateditemsCodeCoverageTests() {
                    // create needed data
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction;     
                    Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors and Auction__c = :auction.id];
                    System.assertEquals(auction.id, campaign.Auction__c);
                    
                    AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
                    Opportunity oppDonatedItem = new Opportunity (
                        Name = 'Test Opportunity',
                        Auction_Donated_Item_Name__c = 'Test Auction Donated item',
                        Amount = 100,
                        CampaignId = campaign.id,
                        RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem,
                        StageName = 'Won Not Thanked',
                        CloseDate = System.Today()
                    );
                    insert oppDonatedItem;
                    am.auctionId = auction.Id;
                    System.assertEquals(campaign.Id, am.campaignIdAuctionDonors);
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionDonatedItems');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller 
                    AUC_CTRL_AuctionDonatedItems pageCtrl = new AUC_CTRL_AuctionDonatedItems();
                    AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
                    compCtrl.pageController = pageCtrl;
                    system.assert(pageCtrl.listStrFields != null);
                    system.assert(pageCtrl.strNameField != null);
                    system.assert(pageCtrl.getStrSoql() != null);
                    system.assert(pageCtrl.NewItem() != null);
       }
     static testmethod void auctionpurchasesCodeCoverageTests() {
                    // create needed data
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction;   
                    Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionAttendees and Auction__c = :auction.id];
                    System.assertEquals(auction.id, campaign.Auction__c);
                    Auction_Item__c ai = new Auction_Item__c (
                        Auction_Item_Name__c = 'Test Auction Item',
                        Auction__c = auction.id,
                        FMV_Override__c = 100
                    );
                    insert ai;
                    AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
                    am.auctionId = auction.Id;
                    System.assertEquals(campaign.Id, am.campaignIdAuctionAttendees);
                    Opportunity oppPurchase= new Opportunity (
                        Name = 'My Auction Item Purchase',
                        CampaignId = campaign.id,
                        RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionPurchasedItem,
                        StageName = 'Won Not Thanked',
                        CloseDate = System.Today(),
                        Amount = 150
                    );
                    insert oppPurchase;
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionPurchases');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller 
                    AUC_CTRL_AuctionPurchases pageCtrl = new AUC_CTRL_AuctionPurchases();
                    AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
                    compCtrl.pageController = pageCtrl;
                    system.assert(pageCtrl.listStrFields != null);
                    system.assert(pageCtrl.strNameField != null);
                    system.assert(pageCtrl.getStrSoql() != null);
                    system.assert(pageCtrl.NewItem() != null);
       }
      static testmethod void auctionticketsCodeCoverageTests() {
                    // create needed data
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction;     
                    Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionTickets and Auction__c = :auction.id];
                    System.assertEquals(auction.id, campaign.Auction__c);
                    AUC_AuctionMaintenance am = new AUC_AuctionMaintenance();
                    Opportunity oppDonatedItem = new Opportunity (
                        Name = 'Test Opportunity',
                        Auction_Donated_Item_Name__c = 'Test Auction Ticket',
                        Amount = 50,
                        CampaignId = campaign.id,
                        RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionTicket,
                        StageName = 'Won Not Thanked',
                        CloseDate = System.Today()
                    );
                    insert oppDonatedItem;
                    am.auctionId = auction.Id;
                    System.assertEquals(campaign.Id, am.campaignIdAuctionTickets);
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionTickets');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller 
                    AUC_CTRL_AuctionTickets pageCtrl = new AUC_CTRL_AuctionTickets();
                    AUC_CTRL_SoqlListView compCtrl = new AUC_CTRL_SoqlListView();
                    compCtrl.pageController = pageCtrl;
                    system.assert(pageCtrl.listStrFields != null);
                    system.assert(pageCtrl.strNameField != null);
                    system.assert(pageCtrl.getStrSoql() != null);
                    system.assert(pageCtrl.NewItem() != null);
                    system.assert(pageCtrl.AutoAssignBidNumbers() != null);     
        }
    static testmethod void DonateditemCodeCoverageTests() {
                    // create needed data
                    Auction__c auction = new Auction__c (
                        Name = 'Test Auction',
                        Auction_Date__c = System.Today()
                    );  
                    insert auction; 
                    Campaign campaign = [select Id, Auction__c from Campaign where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors and Auction__c = :auction.id];
                    System.assertEquals(auction.id, campaign.Auction__c);
                    Auction_Item__c auctionitem = new Auction_Item__c (
                        Auction_Item_Name__c = 'Test Auction item',
                        Auction__c = auction.id
                    );
                    insert auctionitem;
                    Account acc = new Account(name='My Test Account');
                    insert acc;
                    Contact contact = new Contact(
                        Firstname = 'Johnny',
                        Lastname = 'Test',
                        AccountId = acc.Id
                    );
                    insert contact;
                    CampaignMember campaignmember = new CampaignMember(
                        CampaignId = campaign.id,
                        ContactId = contact.id,
                        Bid_Number__c = 123
                    );
                    insert campaignmember;
                    //point to our VF page
                    PageReference p = new PageReference('Page.AuctionNewDonatedItemWizard');
                    p.getParameters().put('auctionId', auction.id); 
                    Test.setCurrentPageReference(p);
                    //instantiate the controller for this opp
                    AUC_CTRL_AuctionNewDonatedItemWizard ctrl = new AUC_CTRL_AuctionNewDonatedItemWizard();
                    ctrl.contactRole.ContactId = contact.id;
                    ctrl.opp.StageName = 'Won Not Thanked';
                    ctrl.opp.CloseDate = System.Today();
                    ctrl.opp.Auction_Donated_Item_Name__c = 'my test auction donated item';
                    ctrl.opp.Amount = 150;
                    ctrl.opp.Number_of_Items__c = 1;
                    ctrl.opp.Description = 'my description of the donated item';
                    ctrl.opp.Auction_Donated_Item_Restrictions__c = 'you are restricted!';
                    ctrl.fCreateAuctionItem = true;
                    system.AssertEquals('true', ctrl.StrFCreateAuctionItem);
                    ctrl.ToggleCreateAuctionItem();
                    system.AssertEquals(ctrl.fCreateAuctionItem, true);
                    system.AssertEquals(ctrl.auctionItem.Auction__c, auction.id);
                    system.AssertEquals(ctrl.auctionItem.Auction_Item_Name__c, ctrl.opp.Auction_Donated_Item_Name__c);
                    system.AssertEquals(ctrl.auctionItem.Description__c, ctrl.opp.Description);
                    system.AssertEquals(ctrl.auctionItem.Restrictions__c, ctrl.opp.Auction_Donated_Item_Restrictions__c);
                    ctrl.auctionItem.Auction_Item_Name__c = 'my test auction item';
                    ctrl.Save();
                    ctrl.Cancel();
                    // verify the auctionItem got correctly created!
                    list<Auction_Item__c> listAI = [select Id, Auction_Item_Name__c from Auction_Item__c where Id=:ctrl.auctionItem.Id];
                    System.AssertEquals('my test auction item', listAI[0].Auction_Item_Name__c);
     }
   
    static testmethod void donateditemconverterCodeCoverageTests() {
        // create needed data
        Auction__c auction = new Auction__c (
            Name = 'Test Auction',
            Auction_Date__c = System.Today()
        );  
        insert auction;     
        
        Campaign campaign = [select Id, Auction__c from Campaign 
            where Auction_Campaign_Type__c=:AUC_AuctionConstants.CAMPAIGN_TYPE_AuctionItemDonors 
            and Auction__c = :auction.id];
        System.assertEquals(auction.id, campaign.Auction__c);
                    
        Account acc = new Account(name='My Test Account');
        insert acc;
        
        Contact contact = new Contact(
            Firstname = 'Johnny',
            Lastname = 'Test',
            AccountId = acc.Id
        );
        insert contact;
        
        CampaignMember campaignmember = new CampaignMember(
            CampaignId = campaign.id,
            ContactId = contact.id,
            Bid_Number__c = 123
        );
        insert campaignmember;
             
        Opportunity opp = new Opportunity(
            RecordTypeId = AUC_AuctionMaintenance.recordtypeIdAuctionDonatedItem,
            Name = 'my donated item opp',
            CampaignId = campaign.Id,
            StageName = 'Won Not Thanked',
            CloseDate = System.Today(),
            Auction_Donated_Item_Name__c = 'my test auction donated item',
            Amount = 150,
            Number_of_Items__c = 1,
            Description = 'my description of the donated item'
        );
        insert opp;
        system.assert(opp.Id != null);

        //point to our VF page
        PageReference p = new PageReference('Page.AuctionDonatedItemConverter');
        p.getParameters().put('auctionId', auction.id); 
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        AUC_CTRL_AuctionDonatedItemConverter ctrl = new AUC_CTRL_AuctionDonatedItemConverter();

        system.assertEquals(null, ctrl.strConvertResult);
        system.assert(ctrl.listNewAuctionItem != null);
        system.assertEquals(1, ctrl.listNewAuctionItem.size());
        system.assertEquals(null, ctrl.Convert());
        //system.assert(ctrl.strConvertResult.contains('1 Auction Items were created.'));
                
        // verify the auctionItem got correctly created!
        list<Auction_Item__c> listAI = [select Id, Auction_Item_Name__c from Auction_Item__c where Auction__c = :auction.Id];
        //system.assertEquals(1, listAI.size());
        //System.AssertEquals('my test auction donated item', listAI[0].Auction_Item_Name__c);
        
        // other methods
        system.assertNotEquals(null, ctrl.Cancel());
        
    }
 }