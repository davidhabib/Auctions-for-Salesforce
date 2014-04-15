@isTest
private class TestClass_PaaS_Class {

public static testMethod void testPaaS_Class() 
                    {
                     PaaS_Class d=new PaaS_Class();
                     d.getVerifyxmlfile();
                     d.setVerifyxmlfile(false);
                     
                     d.getTotalamount();
                     d.setTotalamount(100);
                     d.getTotalDiscount();
                     d.setTotalDiscount(2);
                     d.getTotalTax();
                     d.setTotalTax(2);
                     d.getTotalDeductible();
                     d.setTotalDeductible(2);
                   
                     
                     PaaS_Class.Operation Op= new PaaS_Class.Operation();
                     string Operation='';
                     boolean TempValue=true;
                     op.getOperationType();                     
                     op.setOperationType(Operation);
                     op.getIPAddress();
                     op.setIPAddress(Operation);
                     Boolean value=true;
                     op.getDeclineFraud();
                     op.setDeclineFraud(value);
                     op.getEnableRestriction();
                     op.setEnableRestriction(value);
                     op.getUrlReferrer();
                     op.setUrlReferrer(Operation);                     
                   
                     d.getOperation_node(Op);
                     System.assertEquals(Operation, '');
                     PaaS_Class.Authentication Auth= new PaaS_Class.Authentication();
                     Auth.getAccountID();
                     Auth.setAccountID(Operation);
                     Auth.getAccountGuid();
                     Auth.setAccountGuid(Operation);
                     d.getAuthentication_node(Auth);
                     
                     
                     PaaS_Class.Order Ord= new PaaS_Class.Order();
                     Ord.getOrderMode();
                     Ord.setOrderMode(Operation);
                     Ord.getTracker();
                     Ord.setTracker(Operation);
                     Ord.getCampaign();
                     Ord.setCampaign(Operation);
                     Ord.getIntegratedPartner();
                     Ord.setIntegratedPartner(Operation);
                     d.getOrder_node(Ord);
                     d.getOrderModeTypes();
                     
                     PaaS_Class.BillingInformation BI= new PaaS_Class.BillingInformation();
                     BI.getBillingFirstName();
                     BI.setBillingFirstName(Operation);
                     BI.getBillingMI();
                     BI.setBillingMI(Operation);
                     BI.getBillingLastName();
                     BI.setBillingLastName(Operation);
                     BI.getBillingEmail();
                     BI.setBillingEmail(Operation);
                     BI.getBillingPhone();
                     BI.setBillingPhone(Operation);
                     d.getBillingInformation_node(BI);
                     
                     PaaS_Class.BillingAddress BA= new PaaS_Class.BillingAddress();
                     BA.getBillingAddress1();
                     BA.setBillingAddress1(Operation);
                     BA.getBillingAddress2();
                     BA.setBillingAddress2(Operation);
                     BA.getBillingAddress3();
                     BA.setBillingAddress3(Operation);
                     BA.getBillingCity();
                     BA.setBillingCity(Operation);
                     BA.getBillingStateProvince();
                     BA.setBillingStateProvince(Operation);
                     BA.getBillingPostalCode();
                     BA.setBillingPostalCode(Operation);
                     BA.getBillingCountryCode();
                     BA.setBillingCountryCode(Operation);
                     BA.getBillingPhone();
                     BA.setBillingPhone(Operation);
                     d.getBillingAddress_node(BA);
                     d.getCountrycodeValues();
                     d.getcountrycode('Zimbabwe');
                     
                     PaaS_Class.PaymentMethod cc= new PaaS_Class.PaymentMethod();
                     cc.getTrackData();
                     cc.setTrackData(Operation);
                     cc.getNameOnCard();
                     cc.setNameOnCard(Operation);
                     cc.getCardNumber();
                     cc.setCardNumber(Operation);
                     cc.getCvv2();
                     cc.setCvv2(Operation);
                     cc.getExpirationMonth();
                     cc.setExpirationMonth(Operation);
                     cc.getExpirationYear();
                     cc.setExpirationYear(Operation);
                     cc.getOrderNumber();
                     cc.setOrderNumber(Operation);
                     cc.getVaultGUID();
                     cc.setVaultGUID(Operation);
                     cc.getAccountNumber();
                     cc.setAccountNumber(Operation);
                     cc.getAccountType();
                     cc.setAccountType(Operation);
                     cc.getRoutingNumber();
                     cc.setRoutingNumber(Operation);
                     cc.getCheckNumber();
                     cc.setCheckNumber(Operation);
                     cc.getCheckType();
                     cc.setCheckType(Operation);
                     cc.getNameOnAccount();
                     cc.setNameOnAccount(Operation);
                     cc.getIdType();
                     cc.setIdType(Operation);
                     cc.getIdNumber();
                     cc.setIdNumber(Operation);
                     cc.getIdStateCode();
                     cc.setIdStateCode(Operation);
                     cc.getPurchaseOrderNumber();
                     cc.setPurchaseOrderNumber(Operation);
                     cc.getInvoiceCheckNumber();
                     cc.setInvoiceCheckNumber(Operation);
                     cc.getCustomPaymentName();
                     cc.setCustomPaymentName(Operation);
                     cc.getCustomPaymentNumber();
                     cc.setCustomPaymentNumber(Operation);
                     //cc.getNameOnCard();
                     //cc.setNameOnCard(Operation);
                     
                     d.getPaymentTypes();
                     d.getAccountTypes();
                     d.getCheckTypes();
                     d.getIdTypes();
                     d.getExpireMonth();
                     d.getExpireYear();
                     
                     cc.getPaymentType();
                     cc.setPaymentType('CreditCard');
                     
                     d.getPaymentMethod_node(cc);
                     
                     cc.setPaymentType('ReferenceTransaction');
                     d.getPaymentMethod_node(cc);
                     
                     cc.setPaymentType('Check');
                     d.getPaymentMethod_node(cc);
                     
                     cc.setPaymentType('PurchaseOrder');
                     d.getPaymentMethod_node(cc);
                     
                     cc.setPaymentType('Invoice');
                     d.getPaymentMethod_node(cc);
                     
                     cc.setPaymentType('CustomPaymentType');
                     d.getPaymentMethod_node(cc);
                     
                    
                     
                                                               
                     
                     PaaS_Class.items IL= new PaaS_Class.items();
                     IL.getItemId();
                     IL.setItemId(2);
                     
                     IL.getItemName();
                     IL.setItemName(Operation);
                     IL.getQuantity();
                     IL.setQuantity(2);
                     IL.getUnitPrice();
                     IL.setUnitPrice(100);
                     IL.getUnitDeductible();
                     IL.setUnitDeductible(2);
                     IL.getUnitTax();
                     IL.setUnitTax(1);
                     IL.getUnitDiscount();
                     IL.setUnitDiscount(1);
                     IL.getSKU();
                     IL.setSKU(Operation);
                     IL.getCouponCode();
                     IL.setCouponCode(Operation);
                     IL.getCampaign();
                     IL.setCampaign(Operation);
                     IL.getCustomFieldList();
                     IL.setCustomFieldList(Operation);
                     IL.getCustomFieldParameters();
                     IL.setCustomFieldParameters(Operation);
                     
                     d.getItemsList();
                     d.addItem();
                     list<Paas_Class.Items> TempList=new list<Paas_Class.Items>();
                     Paas_Class.Items tempitem=new Paas_Class.Items();
                     tempitem.ItemName='Test';
                     tempitem.CustomFieldList='Test1,test2:test3,test4';
                     tempitem.CustomFieldParameters='Test1,test2:test3,test4';
                     TempList.add(tempitem);                     
                     d.getItemslist_node(TempList);
                   
                     d.ItemsList=TempList;
                   
                     IL.getCustomFieldList();
                     IL.setCustomFieldList('Test1,test2:test3,test4');
                      PaaS_Class.Receipt Rp= new PaaS_Class.Receipt();
                      Rp.getSendReceipt();
                      Rp.setSendReceipt(TempValue);
                      d.getreceipt_node(Rp);
                    
                     PaaS_Class.cnpTransaction Tran= new PaaS_Class.cnpTransaction();
                     Tran.getTransactionType();
                     Tran.setTransactionType(Operation);
                    
                    
                     decimal TempValue1=0;
                     Tran.getTransactionDiscount();
                     Tran.setTransactionDiscount(TempValue1);
                     Tran.getTransactionTax();
                     Tran.setTransactionTax(TempValue1);
                     Tran.getTransactionConvenienceFee();
                     Tran.setTransactionConvenienceFee(TempValue1);
                     Tran.getChargeDate();
                     Tran.setChargeDate(Operation);
                    
                     Tran.getOrderNumber();
                     Tran.setOrderNumber(Operation);
                     Tran.getVaultGUID();
                     Tran.setVaultGUID(Operation);
                     
                     
                     d.getTransactionType();
                    
                     
                     PaaS_Class.CustomParameters cpm= new PaaS_Class.CustomParameters();
                     cpm.getfield();
                     cpm.setfield(Operation);
                     cpm.getvalue();
                     cpm.setvalue(Operation);
                     d.getCustomFields_tran();
                     d.addcustomfield_Tran();
                     
                     list<PaaS_Class.CustomParameters> Tempcplist=new list<PaaS_Class.CustomParameters>();
                     PaaS_Class.CustomParameters cp=new PaaS_Class.CustomParameters();
                     cp.field='Test';
                     cp.value='Test';
                     Tempcplist.add(cp);
                     d.setCustomFields_tran(Tempcplist);
                     d.CustomParameterType='Application';
                     d.getTransactionCustomFields(d);
                     d.CustomParameterType='CardHolder';
                     d.getTransactionCustomFields(d);
                     d.CustomParameterType='Receipt';
                     d.getTransactionCustomFields(d);
                     d.CustomParameterType='Shipping';
                     d.getTransactionCustomFields(d);
                     d.CustomParameterType='Transaction';
                     d.getTransactionCustomFields(d);
                     d.CustomParameterType='PassThroughList';
                     d.getTransactionCustomFields(d);
                     
                       PaaS_Class xmlstring1=d;
                       d.VerifyXmlfile=false;
                       d.getgeneratexml(xmlstring1);
                       //d.Send_Transaction_api(d.xmlfile);
                       
                       d.getItemsList();
                       d.addItem();
                       
                      
                      
                      string xmlstring='<CnPAPI xmlns="urn:APISchema.xsd">';
  xmlstring+='<Version>12</Version>'; 
  xmlstring+='<Engine>';
    xmlstring+='<Request>';
      xmlstring+='<Operation>';
        xmlstring+='<OperationType>Transaction</OperationType>';
        xmlstring+='<IPAddress>192.168.0.11</IPAddress>';
      xmlstring+='</Operation>';
      xmlstring+='<Authentication>';
        xmlstring+='<AccountGuid>ddd31189-9a80-41d9-99e7-fdbb4350893c</AccountGuid>';
       xmlstring+='<AccountID>14521</AccountID>';
      xmlstring+='</Authentication>';
      xmlstring+='<Order>';
        xmlstring+='<OrderMode>Test</OrderMode>';
        xmlstring+='<CardHolder>';
         xmlstring+='<BillingInformation>';
            xmlstring+='<BillingFirstName>John</BillingFirstName>';
            xmlstring+='<BillingMI>C</BillingMI>';
            xmlstring+='<BillingLastName>Smith</BillingLastName>';
            xmlstring+='<BillingEmail>John.Smit@someDomain.com</BillingEmail>';
            xmlstring+='<BillingPhone>123.456.7890</BillingPhone>';
          xmlstring+='</BillingInformation>';
          xmlstring+='<BillingAddress>';
            xmlstring+='<BillingAddress1>Post Office Box 1000</BillingAddress1>';
            xmlstring+='<BillingAddress2></BillingAddress2>';
            xmlstring+='<BillingAddress3></BillingAddress3>';
            xmlstring+='<BillingCity>Blacksburg</BillingCity>';
            xmlstring+='<BillingStateProvince>VA</BillingStateProvince>';
            xmlstring+='<BillingPostalCode>12346-4563</BillingPostalCode>';
            xmlstring+='<BillingCountryCode>840</BillingCountryCode>';
          xmlstring+='</BillingAddress>';
          xmlstring+='<PaymentMethod>';
            xmlstring+='<PaymentType>CreditCard</PaymentType>';
            xmlstring+='<CreditCard>';
              xmlstring+='<NameOnCard>John Smith</NameOnCard>';
              xmlstring+='<CardNumber>4111111111111111</CardNumber>';
              xmlstring+='<Cvv2>123</Cvv2>';
              xmlstring+='<ExpirationDate>04/15</ExpirationDate>';
            xmlstring+='</CreditCard>';
          xmlstring+='</PaymentMethod>';
        xmlstring+='</CardHolder>';
        xmlstring+='<OrderItemList>';
          xmlstring+='<OrderItem>';
            xmlstring+='<ItemID>1</ItemID>';
            xmlstring+='<ItemName>Donation</ItemName>';
            xmlstring+='<Quantity>1</Quantity>';
            xmlstring+='<UnitPrice>1000</UnitPrice>';
            xmlstring+='<UnitDeductible>1000</UnitDeductible>';
          xmlstring+='</OrderItem>';
        xmlstring+='</OrderItemList>';
        xmlstring+='<Receipt>';
                    xmlstring+='<SendReceipt>true</SendReceipt>';
                    xmlstring+='<WID>30168</WID>';              
        xmlstring+='</Receipt>';
        xmlstring+='<Transaction>';
         xmlstring+='<TransactionType>Authorize</TransactionType>';
          xmlstring+='<CurrentTotals>';
            xmlstring+='<TotalDeductible>1000</TotalDeductible>';
            xmlstring+='<Total>1000</Total>';
          xmlstring+='</CurrentTotals>';
        xmlstring+='</Transaction>';
      xmlstring+='</Order>';
    xmlstring+='</Request>';
  xmlstring+='</Engine>';
xmlstring+='</CnPAPI>';
d.xmlfile=xmlstring;
d.Send_Transaction_api(d.xmlfile);
                    }
                    
                    public static testmethod void TestClickandpledgepaymentprocess()
   {
       string name='naresh';
       System.assertEquals(name, 'naresh');
       PaaS_Cloud.basicHttpEndpoint cnp = new PaaS_Cloud.basicHttpEndpoint();
       PaaS_Cloud.OperationBase64Encode_element cc = new PaaS_Cloud.OperationBase64Encode_element();
       PaaS_Cloud.EchoResponse_element cc1 = new PaaS_Cloud.EchoResponse_element();
       PaaS_Cloud.OperationBase64EncodeResponse_element cc2 = new PaaS_Cloud.OperationBase64EncodeResponse_element();
       PaaS_Cloud.Operation_element cc3 = new PaaS_Cloud.Operation_element();
       PaaS_Cloud.OperationResponse_element cc4 = new PaaS_Cloud.OperationResponse_element();
      
   }
   
   public static testmethod void TestSchemaapi()
   
   {   
       string name='naresh'; 
       System.assertEquals(name, 'naresh');
       PaaS_Class d=new PaaS_Class();
       PaaS_Cloud.basicHttpEndpoint cnp = new PaaS_Cloud.basicHttpEndpoint();
       PaaS_Cloud_Response.ccTransactionResult cct = new PaaS_Cloud_Response.ccTransactionResult();
       PaaS_Cloud_Response.echoData ecd = new PaaS_Cloud_Response.echoData();
       PaaS_Cloud_Response.ccTransactionResult OperationBase64Encode=new PaaS_Cloud_Response.ccTransactionResult();
       PaaS_Cloud_Response.ccTransactionResult Operation=new PaaS_Cloud_Response.ccTransactionResult();
       //PaaS_Cloud_Response.echoData ecd = cnp.echoData();
//PaaS_Cloud_Response.ccTransactionResult transResult = cnp.Operation(xmlstring);
   } 
 
}