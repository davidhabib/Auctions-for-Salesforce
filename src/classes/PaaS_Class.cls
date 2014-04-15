global with sharing class PaaS_Class {
//If this set to true, we can verify xml without submitting
global boolean Verifyxmlfile=false;
                    global boolean getVerifyxmlfile(){return Verifyxmlfile;}
                    global void setVerifyxmlfile(boolean Verifyxmlfile){this.Verifyxmlfile=Verifyxmlfile;}
 
  
  global map<string,string> Options{get;set;}                 
            global void getCountrycodeValues(){
                    options = new map<string,string>();                    
                    options.put('Afghanistan','004');
                    options.put('Albania','008');
                    options.put('Algeria','012');
                    options.put('American Samoa','016');
                    options.put('Andorra','020');
                    options.put('Angola','024');
                    options.put('Antarctica','010');
                    options.put('Antigua and Barbuda','028');
                    options.put('Argentina','032');
                    options.put('Armenia','051');
                    options.put('Aruba','533');
                    options.put('Australia','036');
                    options.put('Austria','040');
                    options.put('Azerbaijan Rep.','031');
                    options.put('Bahamas','044');
                    options.put('Bahrain','048');
                    options.put('Bangladesh','050');
                    options.put('Barbados','052');
                    options.put('Belarus','112');
                    options.put('Belgium','056');
                    options.put('Belize','084');
                    options.put('Benin','204');
                    options.put('Bermuda','060');
                    options.put('Bhutan','064');
                    options.put('Bolivia','068');
                    options.put('Bosnia','070');
                    options.put('Botswana','072');
                    options.put('Brazil','076');
                    options.put('Brunei','096');
                    options.put('Bulgaria','100');
                    options.put('Burkina Faso','854');
                    options.put('Burundi','108');
                    options.put('Cambodia','116');
                    options.put('Cameroon','120');
                    options.put('Canada','124');
                    options.put('Cape Verde Islands','132');
                    options.put('Central African Reglobal','140');
                    options.put('Chad','148');
                    options.put('Chile','152');
                    options.put('China Peoples Reglobal','156');
                    options.put('Columbia','170');
                    options.put('Comoros','174');
                    options.put('Congo','178');
                    options.put('Cook Islands','184');
                    options.put('Costa Rica','188');
                    options.put('Croatia','191');
                    options.put('Cuba','192');
                    options.put('Cyprus','196');
                    options.put('Czech Reglobal','203');
                    options.put('Denmark','208');
                    options.put('Djibouti','262');
                    options.put('Dominican Reglobal','214');
                    options.put('Ecuador','218');
                    options.put('Egypt','818');
                    options.put('El Salvador','222');
                    options.put('Equatorial Guinea Malabo','226');
                    options.put('Eritrea','232');
                    options.put('Estonia','233');
                    options.put('Ethiopia','231');
                    options.put('Fiji Islands','242');
                    options.put('Finland','246');
                    options.put('France','250');
                    options.put('French Guiana','254');
                    options.put('French Polynesia','258');
                    options.put('Gabon','266');
                    options.put('Gambia','270');
                    options.put('Georgia','268');
                    options.put('Germany','276');
                    options.put('Ghana','288');
                    options.put('Gibraltar','292');
                    options.put('Greece','300');
                    options.put('Greenland','304');
                    options.put('Grenada','308');
                    options.put('Guadeloupe','312');
                    options.put('Guam','316');
                    options.put('Guatemala','320');
                    options.put('Guinea','324');
                    options.put('Guyana','328');
                    options.put('Haiti','332');
                    options.put('Honduras','340');
                    options.put('Hong Kong','344');
                    options.put('Hungary','348');
                    options.put('Iceland','352');
                    options.put('India','356');
                    options.put('Indonesia','360');
                    options.put('Iran','364');
                    options.put('Iraq','368');
                    options.put('Ireland','372');
                    options.put('Israel','376');
                    options.put('Italy','380');
                    options.put('Jamaica','388');
                    options.put('Japan','392');
                    options.put('Jordan','400');
                    options.put('Kazakhstan','398');
                    options.put('Kenya','404');
                    options.put('Kiribati','296');
                    options.put('Korea, Reglobal of','410');
                    options.put('Kuwait','414');
                    options.put('Kyrgystan','417');
                    options.put('Latvia','428');
                    options.put('Lebanon','422');
                    options.put('Lesotho','426');
                    options.put('Liberia','430');
                    options.put('Libya','434');
                    options.put('Liechtenstein','438');
                    options.put('Lithuania','440');
                    options.put('Luxembourg','442');
                    options.put('Macao','446');
                    options.put('Macedonia','807');
                    options.put('Madagascar','450');
                    options.put('Malawi','454');
                    options.put('Malaysia','458');
                    options.put('Maldives','462');
                    options.put('Mali','466');
                    options.put('Malta','470');
                    options.put('Marshall Islands','584');
                    options.put('Martinique','474');
                    options.put('Mauritania','478');
                    options.put('Mauritius','480');
                    options.put('Mexico','484');
                    options.put('Micronesia','583');
                    options.put('Moldova','498');
                    options.put('Monaco','492');
                    options.put('Mongolia','496');
                    options.put('Montenegro','499');
                    options.put('Montserrat','500');
                    options.put('Morocco','504');
                    options.put('Mozambique','508');
                    options.put('Myanmar','104');
                    options.put('Namibia','516');
                    options.put('Nauru','520');
                    options.put('Nepal','524');
                    options.put('Netherlands','528');
                    options.put('Netherlands Antilles','530');
                    options.put('New Caledonia','540');
                    options.put('New Zealand','554');
                    options.put('Nicaragua','558');
                    options.put('Niger','562');
                    options.put('Nigeria','566');
                    options.put('Niue','570');
                    options.put('Northern Mariana Islands','580');
                    options.put('Norway','578');
                    options.put('Oman','512');
                    options.put('Pakistan','586');
                    options.put('Palau','585');
                    options.put('Panama','591');
                    options.put('Papua New Guinea','598');
                    options.put('Paraguay','600');
                    options.put('Peru','604');
                    options.put('Phillippines','608');
                    options.put('Poland','616');
                    options.put('Portugal','620');
                    options.put('Qatar','634');
                    options.put('Romania','642');
                    options.put('Russian Federation','643');
                    options.put('Rwanda','646');
                    options.put('Saint Helena','654');
                    options.put('Saint Kitts and Nevis','659');
                    options.put('Saint Pierre and Miquelon','666');
                    options.put('San Marino','674');
                    options.put('Sao Tome and Principe','678');
                    options.put('Saudi Arabia','682');
                    options.put('Senegal','686');
                    options.put('Serbia','688');
                    options.put('Seychelles','690');
                    options.put('Sierra Leone','694');
                    options.put('Singapore','702');
                    options.put('Slovakia','703');
                    options.put('Slovenia','705');
                    options.put('Solomon Islands','090');
                    options.put('Somalia','706');
                    options.put('South Africa','710');
                    options.put('Spain','724');
                    options.put('Sri Lanka','144');
                    options.put('Sudan','736');
                    options.put('Suriname','740');
                    options.put('Swaziland','748');
                    options.put('Sweden','752');
                    options.put('Switzerland','756');
                    options.put('Syria','760');
                    options.put('Taiwan','158');
                    options.put('Tajikistan','762');
                    options.put('Tanzania','834');
                    options.put('Thailand','764');
                    options.put('Tokelau','772');
                    options.put('Tonga','768');
                    options.put('Trinidad and Tobago','780');
                    options.put('Tunisia','788');
                    options.put('Turkey','792');
                    options.put('Turkmenistan','795');
                    options.put('Tuvalu','798');
                    options.put('Uganda','800');
                    options.put('Ukraine','804');
                    options.put('United Arab Emirates','784');
                    options.put('United Kingdom','826');
                    options.put('United States','840');
                    options.put('United States of America','840');
                    options.put('Uruguay','858');
                    options.put('Uzbekistan','860');
                    options.put('Vanuatu','548');
                    options.put('Vatican City','336');
                    options.put('Venzuela','862');
                    options.put('Vietnam','704');
                    options.put('Wallis and Futuna','876');
                    options.put('Western Samoa','016');
                    options.put('Yemen, Peoples Demo. Rep. Of','887');
                    options.put('Yugoslavia','807');
                    options.put('Zambia','894');
                    options.put('Zimbabwe','716');                    
            } 
           global string getcountrycode(string country)
            {
                getCountrycodeValues();
                 string code='';
                 if(country!=null){                 
                    code=options.get(country);
                 }
                 return code;
            } 
//Operation node 
            global class Operation {
                    global string OperationType='';
                    global string getOperationType(){return OperationType;}
                    global void setOperationType(string OperationType){this.OperationType=OperationType;}
                    
                    global string IPAddress='';
                    global string getIPAddress(){return IPAddress;}
                    global void setIPAddress(string IPAddress){this.IPAddress=IPAddress;}

                    global boolean DeclineFraud=true;
                    global boolean getDeclineFraud(){return DeclineFraud;}
                    global void setDeclineFraud(boolean DeclineFraud){this.DeclineFraud=DeclineFraud;}

                    global boolean EnableRestriction=true;
                    global boolean getEnableRestriction(){return EnableRestriction;}
                    global void setEnableRestriction(boolean EnableRestriction){this.EnableRestriction=EnableRestriction;}

                    global string UrlReferrer='';
                    global string getUrlReferrer(){return UrlReferrer;}
                    global void setUrlReferrer(string UrlReferrer){this.UrlReferrer=UrlReferrer;}
                    }
  
            global string Operation {get;set;}
            
            global void getOperation_node(PaaS_Class.Operation OperationObject){

                    Operation='<Operation>';
                    Operation+='<OperationType>Transaction</OperationType>';
                    Operation+='<IPAddress>'+ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP')+'</IPAddress>';
                    Operation+='<DeclineFraud>'+OperationObject.DeclineFraud+'</DeclineFraud>';
                    Operation+='<EnableRestriction>'+OperationObject.EnableRestriction+'</EnableRestriction>';
                    Operation+='<UrlReferrer>'+OperationObject.UrlReferrer+'</UrlReferrer>';
                    Operation+='</Operation>';

                    }

//Operation node end 


//Authentication node start

            global class Authentication {
                    global string AccountID='';
                    global string getAccountID(){return AccountID;}
                    global void setAccountID(string AccountID){this.AccountID=AccountID;}

                    global string AccountGuid='';
                    global string getAccountGuid(){return AccountGuid;}
                    global void setAccountGuid(string AccountGuid){this.AccountGuid=AccountGuid;}
                    }

            global string Authentication{get;set;}
            
            global void getAuthentication_node(PaaS_Class.Authentication AuthenticationObject){
                    Authentication='<Authentication>';
                    Authentication+='<AccountGuid>'+AuthenticationObject.AccountGuid+'</AccountGuid>';
                    Authentication+='<AccountID>'+AuthenticationObject.AccountID+'</AccountID>';
                    Authentication+='</Authentication>';
                    }

//Authentication node End


//Order node start 

            global class Order {
                    global string OrderMode='';
                    global string getOrderMode(){return OrderMode;}
                    global void setOrderMode(string OrderMode){this.OrderMode=OrderMode;}

                    global string Tracker='';
                    global string getTracker(){return Tracker;}
                    global void setTracker(string Tracker){this.Tracker=Tracker;}

                    global string Campaign='';
                    global string getCampaign(){return Campaign;}
                    global void setCampaign(string Campaign){this.Campaign=Campaign;}

                    global string IntegratedPartner='';
                    global string getIntegratedPartner(){return IntegratedPartner;}
                    global void setIntegratedPartner(string IntegratedPartner){this.IntegratedPartner=IntegratedPartner;}
                    }
            
            global list<SelectOption> getOrderModeTypes(){
                    List<SelectOption> Options = new List<SelectOption>();
                    Options.add(new SelectOption('Test','Test'));
                    Options.add(new SelectOption('Production','Production'));
                    
   
                    return Options;
                    }
                    
                    
            global string Order {get;set;}
            
            global void getOrder_node(PaaS_Class.Order OrderObject){
                    Order='<OrderMode>'+OrderObject.OrderMode+'</OrderMode>';
                    Order+='<Tracker><![CDATA['+OrderObject.Tracker+']]></Tracker>';
                    Order+='<Campaign><![CDATA['+OrderObject.Campaign+']]></Campaign>';
                    if(OrderObject.IntegratedPartner!=''){
                    Order+='<IntegratedPartner>'+OrderObject.IntegratedPartner+'</IntegratedPartner>';                    
                    }
                    }


//Order node End

//Billing information node start

            global class BillingInformation {            
                    global string BillingFirstName='';
                    global string getBillingFirstName(){return BillingFirstName;}
                    global void setBillingFirstName(string BillingFirstName){this.BillingFirstName=BillingFirstName;}


                    global string BillingMI='';
                    global string getBillingMI(){return BillingMI;}
                    global void setBillingMI(string BillingMI){this.BillingMI=BillingMI;}


                    global string BillingLastName='';
                    global string getBillingLastName(){return BillingLastName;}
                    global void setBillingLastName(string BillingLastName){this.BillingLastName=BillingLastName;}


                    global string BillingEmail='';
                    global string getBillingEmail(){return BillingEmail;}
                    global void setBillingEmail(string BillingEmail){this.BillingEmail=BillingEmail;}


                    global string BillingPhone='';
                    global string getBillingPhone(){return BillingPhone;}
                    global void setBillingPhone(string BillingPhone){this.BillingPhone=BillingPhone;}
              
                    }

            global string BillingInformation{get;set;}
            
            global void getBillingInformation_node(PaaS_Class.BillingInformation billing){
            
                    BillingInformation='<BillingInformation>';                  
                    BillingInformation+='<BillingFirstName><![CDATA['+billing.BillingFirstName+']]></BillingFirstName>';                    
                    BillingInformation+='<BillingMI>'+billing.BillingMI+'</BillingMI>';
                    BillingInformation+='<BillingLastName><![CDATA['+billing.BillingLastName+']]></BillingLastName>';
                    if(billing.BillingEmail!=''){
                    BillingInformation+='<BillingEmail>'+billing.BillingEmail+'</BillingEmail>';
                    }if(billing.BillingPhone!=''){
                    BillingInformation+='<BillingPhone>'+billing.BillingPhone+'</BillingPhone>';
                    }
                    BillingInformation+='</BillingInformation>';

                    }

//Billing information node end

//Billing address node start

            global class BillingAddress {
                    global string BillingAddress1='';
                    global string getBillingAddress1(){return BillingAddress1;}
                    global void setBillingAddress1(string BillingAddress1){this.BillingAddress1=BillingAddress1;}

                    
                    global string BillingAddress2='';
                    global string getBillingAddress2(){return BillingAddress2;}
                    global void setBillingAddress2(string BillingAddress2){this.BillingAddress2=BillingAddress2;}

                    
                    global string BillingAddress3='';
                    global string getBillingAddress3(){return BillingAddress3;}
                    global void setBillingAddress3(string BillingAddress3){this.BillingAddress3=BillingAddress3;}

                    
                    global string BillingCity='';
                    global string getBillingCity(){return BillingCity;}
                    global void setBillingCity(string BillingCity){this.BillingCity=BillingCity;}

                    
                    global string BillingStateProvince='';
                    global string getBillingStateProvince(){return BillingStateProvince;}
                    global void setBillingStateProvince(string BillingStateProvince){this.BillingStateProvince=BillingStateProvince;}

                    
                    global string BillingPostalCode='';
                    global string getBillingPostalCode(){return BillingPostalCode;}
                    global void setBillingPostalCode(string BillingPostalCode){this.BillingPostalCode=BillingPostalCode;}

                    
                    global string BillingCountryCode='840';
                    global string getBillingCountryCode(){return BillingCountryCode;}
                    global void setBillingCountryCode(string BillingCountryCode){this.BillingCountryCode=BillingCountryCode;}
                    
                    global string BillingPhone='';//UnUsed
                    global string getBillingPhone(){return BillingPhone;}//UnUsed
                    global void setBillingPhone(string BillingPhone){this.BillingPhone=BillingPhone;}//UnUsed
                    }
            global string BillingAddress{get;set;}

            global void getBillingAddress_node(PaaS_Class.BillingAddress BillingAddressObject){
                    BillingAddress='<BillingAddress>';
                    if(BillingAddressObject.BillingAddress1!=''){
                    BillingAddress+='<BillingAddress1><![CDATA['+BillingAddressObject.BillingAddress1+']]></BillingAddress1>';
                    }
                    BillingAddress+='<BillingAddress2><![CDATA['+BillingAddressObject.BillingAddress2+']]></BillingAddress2>';
                    BillingAddress+='<BillingAddress3><![CDATA['+BillingAddressObject.BillingAddress3+']]></BillingAddress3>';
                    if(BillingAddressObject.BillingCity!=''){
                    BillingAddress+='<BillingCity><![CDATA['+BillingAddressObject.BillingCity+']]></BillingCity>';
                    }
                    BillingAddress+='<BillingStateProvince><![CDATA['+BillingAddressObject.BillingStateProvince+']]></BillingStateProvince>';
                    if(BillingAddressObject.BillingPostalCode!=''){
                    BillingAddress+='<BillingPostalCode><![CDATA['+BillingAddressObject.BillingPostalCode+']]></BillingPostalCode>';
                    }if(BillingAddressObject.BillingCountryCode!=''){
                    BillingAddress+='<BillingCountryCode>'+BillingAddressObject.BillingCountryCode+'</BillingCountryCode>';
                    }
                    BillingAddress+='</BillingAddress>';

                    }

//Billing address node end

//Payment method node start

            global class PaymentMethod {
            //Credit card
            
                    global string PaymentType='CreditCard';
                    global string getPaymentType(){return PaymentType;}
                    global void setPaymentType(string PaymentType){this.PaymentType=PaymentType;}
                    
                    global string NameOnCard='';
                    global string getNameOnCard(){return NameOnCard;}
                    global void setNameOnCard(string NameOnCard){this.NameOnCard=NameOnCard;}
                    
                    global string CardNumber='';
                    global string getCardNumber(){return CardNumber;}
                    global void setCardNumber(string CardNumber){this.CardNumber=CardNumber;}
                    
                    global string Cvv2='';
                    global string getCvv2(){return Cvv2;}
                    global void setCvv2(string Cvv2){this.Cvv2=Cvv2;}
                    
                    global string ExpirationMonth='';
                    global string getExpirationMonth(){return ExpirationMonth;}
                    global void setExpirationMonth(string ExpirationMonth){this.ExpirationMonth=ExpirationMonth;}
                    
                    global string ExpirationYear='';
                    global string getExpirationYear(){return ExpirationYear;}
                    global void setExpirationYear(string ExpirationYear){this.ExpirationYear=ExpirationYear;}
                    
                    global string TrackData='';
                    global string getTrackData(){return TrackData;}
                    global void setTrackData(string TrackData){this.TrackData=TrackData;}
                
            // Reference transaction
                    global string OrderNumber='';
                    global string getOrderNumber(){return OrderNumber;}
                    global void setOrderNumber(string OrderNumber){this.OrderNumber=OrderNumber;}
                    
                    global string VaultGUID='';
                    global string getVaultGUID(){return VaultGUID;}
                    global void setVaultGUID(string VaultGUID){this.VaultGUID=VaultGUID;}
                
            //Check
                    global string AccountNumber='';
                    global string getAccountNumber(){return AccountNumber;}
                    global void setAccountNumber(string AccountNumber){this.AccountNumber=AccountNumber;}
                    
                    global string AccountType='';
                    global string getAccountType(){return AccountType;}
                    global void setAccountType(string AccountType){this.AccountType=AccountType;}
                    
                    global string RoutingNumber='';
                    global string getRoutingNumber(){return RoutingNumber;}
                    global void setRoutingNumber(string RoutingNumber){this.RoutingNumber=RoutingNumber;}
                    
                    global string CheckNumber='';
                    global string getCheckNumber(){return CheckNumber;}
                    global void setCheckNumber(string CheckNumber){this.CheckNumber=CheckNumber;}
                    
                    global string CheckType='';
                    global string getCheckType(){return CheckType;}
                    global void setCheckType(string CheckType){this.CheckType=CheckType;}
                    
                    global string NameOnAccount='';
                    global string getNameOnAccount(){return NameOnAccount;}
                    global void setNameOnAccount(string NameOnAccount){this.NameOnAccount=NameOnAccount;}
                    
                    global string IdType='';
                    global string getIdType(){return IdType;}
                    global void setIdType(string IdType){this.IdType=IdType;}
                    
                    global string IdNumber='';
                    global string getIdNumber(){return IdNumber;}
                    global void setIdNumber(string IdNumber){this.IdNumber=IdNumber;}
                    
                    global string IdStateCode='';
                    global string getIdStateCode(){return IdStateCode;}
                    global void setIdStateCode(string IdStateCode){this.IdStateCode=IdStateCode;}
                
            //PurchaseOrder 
                    global string PurchaseOrderNumber='';
                    global string getPurchaseOrderNumber(){return PurchaseOrderNumber;}
                    global void setPurchaseOrderNumber(string PurchaseOrderNumber){this.PurchaseOrderNumber=PurchaseOrderNumber;}
                
            //Invoice
                    global string InvoiceCheckNumber='';
                    global string getInvoiceCheckNumber(){return InvoiceCheckNumber;}
                    global void setInvoiceCheckNumber(string InvoiceCheckNumber){this.InvoiceCheckNumber=InvoiceCheckNumber;}
                
            //Custom PaymentType
                    global string CustomPaymentName='';
                    global string getCustomPaymentName(){return CustomPaymentName;}
                    global void setCustomPaymentName(string CustomPaymentName){this.CustomPaymentName=CustomPaymentName;}
                    
                    global string CustomPaymentNumber='';
                    global string getCustomPaymentNumber(){return CustomPaymentNumber;}
                    global void setCustomPaymentNumber(string CustomPaymentNumber){this.CustomPaymentNumber=CustomPaymentNumber;}
                                    
            }

            //Get the supported payment types by cnp api

            global list<SelectOption> getPaymentTypes(){
            
                    List<SelectOption> Options = new List<SelectOption>();
                        
                        Options.add(new SelectOption('CreditCard','Credit card'));
                        Options.add(new SelectOption('ReferenceTransaction','Reference transaction'));
                        Options.add(new SelectOption('Check','Check'));
                        Options.add(new SelectOption('PurchaseOrder','Purchase order'));
                        Options.add(new SelectOption('Invoice','Invoice'));
                        Options.add(new SelectOption('CustomPaymentType','Custom payment type'));
                    return Options;
                    }
                    

            global list<SelectOption> getAccountTypes(){
                    List<SelectOption> Options = new List<SelectOption>();
  
                    Options.add(new SelectOption('SavingsAccount','Savings account'));
                    Options.add(new SelectOption('CheckingAccount','Checking account'));
   
                    return Options;
                    }
                    
  
            global list<SelectOption> getCheckTypes(){
                    List<SelectOption> Options = new List<SelectOption>();
  
                    Options.add(new SelectOption('Company','Company'));
                    Options.add(new SelectOption('Personal','Personal'));
   
                    return Options;
                    }
                    
  
            global list<SelectOption> getIdTypes(){
                    List<SelectOption> Options = new List<SelectOption>();
  
                    Options.add(new SelectOption('Driver','Driver'));
                    Options.add(new SelectOption('Military','Military'));
                    Options.add(new SelectOption('State','State'));
   
                    return Options;
                    }
                    
            global list<SelectOption> getExpireMonth(){
                    List<SelectOption> Options = new List<SelectOption>();
                    options.add(new SelectOption('--Select--','--Select--'));
                    options.add(new SelectOption('01','January(01)'));
                    options.add(new SelectOption('02','February(02)'));
                    options.add(new SelectOption('03','March(03)'));
                    options.add(new SelectOption('04','April(04)'));
                    options.add(new SelectOption('05','May(05)'));
                    options.add(new SelectOption('06','June(06)'));
                    options.add(new SelectOption('07','July(07)'));
                    options.add(new SelectOption('08','August(08)'));
                    options.add(new SelectOption('09','September(09)'));
                    options.add(new SelectOption('10','October(10)'));
                    options.add(new SelectOption('11','November(11)'));
                    options.add(new SelectOption('12','December(12)'));
                    
                    return Options;
            }
            
            global list<SelectOption> getExpireYear(){
            List<SelectOption> Options = new List<SelectOption>();
            datetime CurrentDate=system.now();
            
            for(Integer i=0; i<=10;i++){
            Integer CurrentYear=CurrentDate.year();
            integer ShortCurrentYear=Integer.valueof(string.valueof(CurrentYear).substring(2,4));
            CurrentYear=CurrentYear+i;
            ShortCurrentYear=ShortCurrentYear+i;
            options.add(new SelectOption(''+ShortCurrentYear+'',''+CurrentYear+''));
            
            }
            
            return Options;
            }


            global string PaymentMethod{get;set;}
            
            global void getPaymentMethod_node(PaaS_Class.PaymentMethod PaymentMethodObject){
                    PaymentMethod='<PaymentMethod>';
                    PaymentMethod+='<PaymentType>'+PaymentMethodObject.PaymentType+'</PaymentType>';
                    
                    if(PaymentMethodObject.PaymentType=='CreditCard'){
                        PaymentMethod+='<CreditCard>';
                        PaymentMethod+='<NameOnCard><![CDATA['+PaymentMethodObject.NameOnCard+']]></NameOnCard>';
                        PaymentMethod+='<CardNumber>'+PaymentMethodObject.CardNumber+'</CardNumber>';
                        PaymentMethod+='<Cvv2>'+PaymentMethodObject.Cvv2+'</Cvv2>';
                        PaymentMethod+='<ExpirationDate>'+PaymentMethodObject.ExpirationMonth+'/'+PaymentMethodObject.ExpirationYear+'</ExpirationDate>';
                        if(PaymentMethodObject.TrackData!=''){
                        PaymentMethod+='<TrackData>'+PaymentMethodObject.TrackData+'</TrackData>';
                        }
                        PaymentMethod+='</CreditCard>';
                    }
                    
                    else if(PaymentMethodObject.PaymentType=='ReferenceTransaction'){
                        PaymentMethod+='<ReferenceTransaction>';
                        PaymentMethod+='<OrderNumber>'+PaymentMethodObject.OrderNumber+'</OrderNumber>';
                        PaymentMethod+='<VaultGUID>'+PaymentMethodObject.VaultGUID+'</VaultGUID>';
                        PaymentMethod+='</ReferenceTransaction>';
                    }
                    
                    else if(PaymentMethodObject.PaymentType=='Check'){
                        PaymentMethod+='<Check>';
                        PaymentMethod+='<AccountNumber>'+PaymentMethodObject.AccountNumber+'</AccountNumber>';
                        PaymentMethod+='<AccountType>'+PaymentMethodObject.AccountType+'</AccountType>';
                        PaymentMethod+='<RoutingNumber>'+PaymentMethodObject.RoutingNumber+'</RoutingNumber>';
                        PaymentMethod+='<CheckNumber><![CDATA['+PaymentMethodObject.CheckNumber+']]></CheckNumber>';
                        PaymentMethod+='<CheckType>'+PaymentMethodObject.CheckType+'</CheckType>';
                        PaymentMethod+='<NameOnAccount>'+PaymentMethodObject.NameOnAccount+'</NameOnAccount>';
                        if(PaymentMethodObject.IdType!=''){
                        PaymentMethod+='<IdType>'+PaymentMethodObject.IdType+'</IdType>';
                        }
                        PaymentMethod+='<IdNumber>'+PaymentMethodObject.IdNumber+'</IdNumber>';
                        PaymentMethod+='<IdStateCode>'+PaymentMethodObject.IdStateCode+'</IdStateCode>';
                        PaymentMethod+='</Check>';
                    }
                    
                    else if(PaymentMethodObject.PaymentType=='PurchaseOrder'){
                        PaymentMethod+='<PurchaseOrder>';
                        PaymentMethod+='<PurchaseOrderNumber><![CDATA['+PaymentMethodObject.PurchaseOrderNumber+']]></PurchaseOrderNumber>';
                        PaymentMethod+='</PurchaseOrder>';
                    }
                    else if(PaymentMethodObject.PaymentType=='Invoice'){
                        PaymentMethod+='<Invoice>';
                        PaymentMethod+='<InvoiceCheckNumber>'+PaymentMethodObject.InvoiceCheckNumber+'</InvoiceCheckNumber>';
                        PaymentMethod+='</Invoice>';
                    }
                    else if(PaymentMethodObject.PaymentType=='CustomPaymentType'){
                        PaymentMethod+='<CustomPaymentType>';
                        PaymentMethod+='<CustomPaymentName><![CDATA['+PaymentMethodObject.CustomPaymentName+']]></CustomPaymentName>';
                        if(PaymentMethodObject.CustomPaymentNumber!=''){
                        PaymentMethod+='<CustomPaymentNumber>'+PaymentMethodObject.CustomPaymentNumber+'</CustomPaymentNumber>';  
                        }             
                        PaymentMethod+='</CustomPaymentType>';
                    
                    }
                    
            PaymentMethod+='</PaymentMethod>';
            
            }

//Payment method node end

 //Item list node start
            global class Items {
                    global integer ItemId=1;
                    global integer getItemId(){return ItemId;}
                    global void setItemId(integer ItemId){this.ItemId=ItemId;}
                    
                    global string ItemName='';
                    global string getItemName(){return ItemName;}
                    global void setItemName(string ItemName){this.ItemName=ItemName;}
                    
                    global integer Quantity=1;
                    global integer getQuantity(){return Quantity;}
                    global void setQuantity(integer Quantity){this.Quantity=Quantity;}
                    
                    global decimal UnitPrice=0;
                    global decimal getUnitPrice(){return UnitPrice;}
                    global void setUnitPrice(decimal UnitPrice){this.UnitPrice=UnitPrice;}
                    
                    global decimal UnitDeductible=0;
                    global decimal getUnitDeductible(){return UnitDeductible;}
                    global void setUnitDeductible(decimal UnitDeductible){this.UnitDeductible=UnitDeductible;}
                    
                    global decimal UnitTax=0;
                    global decimal getUnitTax(){return UnitTax;}
                    global void setUnitTax(decimal UnitTax){this.UnitTax=UnitTax;}

                    global decimal UnitDiscount=0;
                    global decimal getUnitDiscount(){return UnitDiscount;}
                    global void setUnitDiscount(decimal UnitDiscount){this.UnitDiscount=UnitDiscount;}
                    
                    global string SKU='';
                    global string getSKU(){return SKU;}
                    global void setSKU(string SKU){this.SKU=SKU;}
                    
                    global string CouponCode='';
                    global string getCouponCode(){return CouponCode;}
                    global void setCouponCode(string CouponCode){this.CouponCode=CouponCode;}
                    
                    global string Campaign='';
                    global string getCampaign(){return Campaign;}
                    global void setCampaign(string Campaign){this.Campaign=Campaign;}
                    
                    global string CustomFieldList='';
                    global string getCustomFieldList(){return CustomFieldList;}
                    global void setCustomFieldList(string CustomFieldList){this.CustomFieldList=CustomFieldList;}
                    
                    global string CustomFieldParameters='';
                    global string getCustomFieldParameters(){return CustomFieldParameters;}
                    global void setCustomFieldParameters(string CustomFieldParameters){this.CustomFieldParameters=CustomFieldParameters;}
             }

            global list<items> ItemsList;

            global list<items> getItemsList(){
            
                    if(ItemsList==null) {
                      ItemsList= new list<items>();
                      ItemsList.add(new items());
                    }
                    return ItemsList;
            }

            global void setItems(list<items> items) {
                    ItemsList = items;
            }
  
            global void addItem() {
                    ItemsList.add(new items());
            }
            
            global string Items {get;set;}
            global decimal Totalamount=0;
            global decimal getTotalamount(){return Totalamount;}
            global void setTotalamount(decimal Totalamount){this.Totalamount=Totalamount;}                        
            
            global decimal TotalDiscount=0;
            global decimal getTotalDiscount(){return TotalDiscount;}
            global void setTotalDiscount(decimal TotalDiscount){this.TotalDiscount=TotalDiscount;}            
            
            global decimal TotalTax=0;
            global decimal getTotalTax(){return TotalTax;}
            global void setTotalTax(decimal TotalTax){this.TotalTax=TotalTax;}            
            
            global decimal TotalDeductible=0;
            global decimal getTotalDeductible(){return TotalDeductible;}
            global void setTotalDeductible(decimal TotalDeductible){this.TotalDeductible=TotalDeductible;}

global void getItemslist_node(list<items> ItemsList){
                    Totalamount=0;
                    TotalDiscount=0;
                    TotalTax=0;
                    TotalDeductible=0;
                    Items='<OrderItemList>';
                    
                    for(Items i : ItemsList){
                        Items+='<OrderItem>';
                        Items+='<ItemID>'+i.ItemId+'</ItemID>';
                        Items+='<ItemName><![CDATA['+i.ItemName+']]></ItemName>';
                        Items+='<Quantity>'+i.Quantity+'</Quantity>';
                        
                        Items+='<UnitPrice>'+(i.UnitPrice*100).setscale(0)+'</UnitPrice>';
                        Items+='<UnitDeductible>'+(i.UnitDeductible*100).setscale(0)+'</UnitDeductible>';
                        TotalDeductible=TotalDeductible+(i.UnitDeductible*i.Quantity*100).setscale(0);
                        Items+='<UnitTax>'+(i.UnitTax*100).setscale(0)+'</UnitTax>';
                        TotalTax=TotalTax+(i.UnitTax*i.Quantity*100).setscale(0);
                        Items+='<UnitDiscount>'+(i.UnitDiscount*100).setscale(0)+'</UnitDiscount>';
                        TotalDiscount=TotalDiscount+(i.UnitDiscount*i.Quantity*100).setscale(0);
                        Totalamount=Totalamount+(i.Quantity*i.UnitPrice*100).setscale(0);
                        Items+='<SKU>'+i.SKU+'</SKU>';
                        Items+='<CouponCode>'+i.CouponCode+'</CouponCode>';
                        if(i.CustomFieldParameters!=''){
                        Items+='<CustomParameters>';
                        system.debug('check i.CustomFieldList' + i.CustomFieldParameters);
                        string[] ItemFieldsList=i.CustomFieldParameters.split(':');
                        for(string s : ItemFieldsList){
                        string[] ItemFields=s.split(',');
                        system.debug('check ItemFields' + ItemFields);
                        Items+='<Parameter>';
                        Items+='<Field><![CDATA['+ItemFields[0]+']]></Field>';
                        Items+='<Value><![CDATA['+ItemFields[1]+']]></Value>';
                        Items+='</Parameter>';
                        }
                        Items+='</CustomParameters>';
                        }
                        
                        Items+='<Campaign><![CDATA['+i.Campaign+']]></Campaign>';
                        if(i.CustomFieldList!=''){
                        Items+='<CustomFieldList>';
                        system.debug('check i.CustomFieldList' + i.CustomFieldList);
                        string[] ItemFieldsList=i.CustomFieldList.split(':');
                        for(string s : ItemFieldsList){
                        string[] ItemFields=s.split(',');
                        system.debug('check ItemFields' + ItemFields);
                        Items+='<CustomField>';
                        Items+='<FieldName><![CDATA['+ItemFields[0]+']]></FieldName>';
                        Items+='<FieldValue><![CDATA['+ItemFields[1]+']]></FieldValue>';
                        Items+='</CustomField>';
                        }
                        Items+='</CustomFieldList>';
                        }
                        
                        
                        Items+='</OrderItem>';
                        
                    }          
                    Items+='</OrderItemList>';                
}                      
   
//Item list node end 
//Reciept node start
            global class Receipt {
                    global Boolean SendReceipt=true;
                    global Boolean getSendReceipt(){return SendReceipt;}
                    global void setSendReceipt(Boolean SendReceipt){this.SendReceipt=SendReceipt;}
                    
                    global string CheckOutPageID='';
                    global string getCheckOutPageID(){return CheckOutPageID;}
                    global void setCheckOutPageID(string CheckOutPageID){this.CheckOutPageID=CheckOutPageID;}
                    
                    global string WID='';
                    global string getWID(){return WID;}
                    global void setWID(string WID){this.WID=WID;}
                    
                    global string Language='ENG';
                    global string getLanguage(){return Language;}
                    global void setLanguage(string Language){this.Language=Language;}
                                        
                    global string OrganizationInformation='';
                    global string getOrganizationInformation(){return OrganizationInformation;}
                    global void setOrganizationInformation(string OrganizationInformation){this.OrganizationInformation=OrganizationInformation;}
                    
                    global string ThankYouMessage='';
                    global string getThankYouMessage(){return ThankYouMessage;}
                    global void setThankYouMessage(string ThankYouMessage){this.ThankYouMessage=ThankYouMessage;}
                    
                    
                    global string TermsCondition='';
                    global string getTermsCondition(){return TermsCondition;}
                    global void setTermsCondition(string TermsCondition){this.TermsCondition=TermsCondition;}

                    global Boolean Deductible=false;
                    global Boolean getDeductible(){return Deductible;}
                    global void setDeductible(Boolean Deductible){this.Deductible=Deductible;}

                    global string EmailNotificationList='';
                    global string getEmailNotificationList(){return EmailNotificationList;}
                    global void setEmailNotificationList(string EmailNotificationList){this.EmailNotificationList=EmailNotificationList;}
            }
            
            global list<SelectOption> getsupportedLanguages(){
                    List<SelectOption> Options = new List<SelectOption>();
                    Options.add(new SelectOption('ENG','ENG'));
                    Options.add(new SelectOption('CHN','CHN'));
                    Options.add(new SelectOption('DEU','DEU'));
                    Options.add(new SelectOption('ITA','ITA'));
                    Options.add(new SelectOption('POL','POL'));
                    Options.add(new SelectOption('JAP','JAP'));
                    Options.add(new SelectOption('RUS','RUS'));
                    Options.add(new SelectOption('FRN','FRN'));
                    Options.add(new SelectOption('POR','POR'));
                    Options.add(new SelectOption('SPN','SPN'));
                       
                    return Options;
                    }
            
            global string Receipt{get;set;}
            
            global void getReceipt_node(PaaS_Class.Receipt ReceiptObject){
                    receipt='<Receipt>';
                    receipt+='<SendReceipt>'+ReceiptObject.SendReceipt+'</SendReceipt>';
                    if(ReceiptObject.CheckOutPageID!=''){
                    receipt+='<CheckOutPageID>'+ReceiptObject.CheckOutPageID+'</CheckOutPageID>';
                    }if(ReceiptObject.WID!=''){ 
                    receipt+='<WID>'+ReceiptObject.WID+'</WID>';
                    } 
                    receipt+='<Language>'+ReceiptObject.Language+'</Language>';                  
                    receipt+='<OrganizationInformation><![CDATA['+ReceiptObject.OrganizationInformation+']]></OrganizationInformation>';
                    receipt+='<ThankYouMessage><![CDATA['+ReceiptObject.ThankYouMessage+']]></ThankYouMessage>';
                    receipt+='<TermsCondition><![CDATA['+ReceiptObject.TermsCondition+']]></TermsCondition>';
                    receipt+='<Deductible>'+ReceiptObject.Deductible+'</Deductible>';
                    if(ReceiptObject.EmailNotificationList!=''){
                    string[] EmailList=ReceiptObject.EmailNotificationList.split(';');
                    receipt+='<EmailNotificationList>';
                    for(string s : EmailList){
                    receipt+='<NotificationEmail>'+s+'</NotificationEmail>';
                    }
                    receipt+='</EmailNotificationList>';
                    }
                    if(ReceiptCustomParameters!=null){
                    receipt+=ReceiptCustomParameters;
                    }
                    receipt+='</Receipt>';
            }            
//Reciept node end 

//Transaction node start

            global class CnPTransaction {
                    global string TransactionType='';//Authorize
                    global string getTransactionType(){return TransactionType;}
                    global void setTransactionType(string TransactionType){this.TransactionType=TransactionType;}
                    
                    global decimal TransactionDiscount=0;
                    global decimal getTransactionDiscount(){return TransactionDiscount;}
                    global void setTransactionDiscount(decimal TransactionDiscount){this.TransactionDiscount=TransactionDiscount;}
                    
                    global decimal TransactionTax=0;
                    global decimal getTransactionTax(){return TransactionTax;}
                    global void setTransactionTax(decimal TransactionTax){this.TransactionTax=TransactionTax;}
                    
                    global decimal TransactionConvenienceFee=0;
                    global decimal getTransactionConvenienceFee(){return TransactionConvenienceFee;}
                    global void setTransactionConvenienceFee(decimal TransactionConvenienceFee){this.TransactionConvenienceFee=TransactionConvenienceFee;}
                    
                    global string ChargeDate='';
                    global string getChargeDate(){return ChargeDate;}
                    global void setChargeDate(string ChargeDate){this.ChargeDate=ChargeDate;}
                    
                    
                    
                    //Reference transaction

                    global string OrderNumber='';
                    global string getOrderNumber(){return OrderNumber;}
                    global void setOrderNumber(string OrderNumber){this.OrderNumber=OrderNumber;}
                    
                    global string VaultGUID='';
                    global string getVaultGUID(){return VaultGUID;}
                    global void setVaultGUID(string VaultGUID){this.VaultGUID=VaultGUID;}
                                    
                    
            }

            global list<SelectOption> getTransactionType(){
                    List<SelectOption> Options = new List<SelectOption>();
                    Options.add(new SelectOption('Authorize','Authorize'));
                    Options.add(new SelectOption('Payment','Payment'));
                    Options.add(new SelectOption('PreAuthorization','PreAuthorization'));
                    Options.add(new SelectOption('Refund','Refund'));
                    return Options;
            }
            
            //Custom fields in Transaction node
            global string CustomParameterType {get;set;}
            
            global class CustomParameters{
            global string field='';
                    global string getfield(){return field;}
                    global void setfield(string field){this.field=field;}
            
            global string value='';
                    global string getvalue(){return value;}
                    global void setvalue(string value){this.value=value;}
            
            }
            
            
            global list<CustomParameters> CustomFields_tran;
            
            global list<CustomParameters> getCustomFields_tran(){
                    if(CustomFields_tran==null) {
                        CustomFields_tran= new list<CustomParameters>();
                        CustomFields_tran.add(new CustomParameters());
                        }
                        
                    return CustomFields_tran;
                    }

            global void setCustomFields_tran(list<CustomParameters> items) {
                    CustomFields_tran= items;
                    }
  
            global void addcustomfield_Tran() {
                    CustomFields_tran.add(new CustomParameters());
                    }
                    
                    
            global string ApplicationCustomParameters{get;set;}        
            global string CardHolderCustomParameters{get;set;}
            global string ShippingCustomParameters{get;set;}
            global string ReceiptCustomParameters{get;set;}
            global string TransactionCustomParameters{get;set;} 
            global string PassThroughListCustomParameters{get;set;}       
            global void getTransactionCustomFields(PaaS_Class xmlstring){
            
           
            if(CustomParameterType =='CardHolder'){
                    CardHolderCustomParameters='<CustomParameters>';
                    
                    for(CustomParameters i : xmlstring.CustomFields_tran){
                        CardHolderCustomParameters+='<Parameter>';
                        CardHolderCustomParameters+='<Field><![CDATA['+i.field+']]></Field>';
                        CardHolderCustomParameters+='<Value><![CDATA['+i.value+']]></Value>';
                        CardHolderCustomParameters+='</Parameter>';
                        }
                    CardHolderCustomParameters+='</CustomParameters>';
                    
                }
                 if(CustomParameterType =='Receipt'){
                    ReceiptCustomParameters='<CustomParameters>';
                    
                    for(CustomParameters i : xmlstring.CustomFields_tran){
                        ReceiptCustomParameters+='<Parameter>';
                        ReceiptCustomParameters+='<Field><![CDATA['+i.field+']]></Field>';
                        ReceiptCustomParameters+='<Value><![CDATA['+i.value+']]></Value>';
                        ReceiptCustomParameters+='</Parameter>';
                        }
                    ReceiptCustomParameters+='</CustomParameters>';
                    
                }
                
              
                
            if(CustomParameterType =='Transaction'){
                    TransactionCustomParameters='<CustomParameters>';
                    
                    for(CustomParameters i : xmlstring.CustomFields_tran){
                        TransactionCustomParameters+='<Parameter>';
                        TransactionCustomParameters+='<Field><![CDATA['+i.field+']]></Field>';
                        TransactionCustomParameters+='<Value><![CDATA['+i.value+']]></Value>';
                        TransactionCustomParameters+='</Parameter>';
                        }
                    TransactionCustomParameters+='</CustomParameters>';
                    
                }
            }        

            global string TransactionDetails{get;set;}
            
            global void getTransactionDetails_node(PaaS_Class.CnPTransaction Tran){
                    TransactionDetails='<Transaction>';
                    TransactionDetails+='<TransactionType>'+Tran.TransactionType+'</TransactionType>';
                    TransactionDetails+='<CurrentTotals>';
                    TransactionDetails+='<TotalDiscount>'+(TotalDiscount+(Tran.TransactionDiscount*100)).setscale(0)+'</TotalDiscount>';
                    TransactionDetails+='<TotalTax>'+(TotalTax+(Tran.TransactionTax*100)).setscale(0)+'</TotalTax>';
                    TransactionDetails+='<TotalDeductible>'+TotalDeductible.setscale(0)+'</TotalDeductible>';
                    TotalAmount =(Totalamount+TotalTax-TotalDiscount+(Tran.TransactionTax*100)+(Tran.TransactionConvenienceFee*100)-(Tran.TransactionDiscount*100)).setscale(0);
                    if(TotalAmount < 0 ){TotalAmount =0;}
                    TransactionDetails+='<Total>'+TotalAmount+'</Total>';
                    TransactionDetails+='</CurrentTotals>';
                    TransactionDetails+='<TransactionDiscount>'+(Tran.TransactionDiscount*100).setscale(0)+'</TransactionDiscount>';
                    TransactionDetails+='<TransactionTax>'+(Tran.TransactionTax*100).setscale(0)+'</TransactionTax>';
                    TransactionDetails+='<TransactionConvenienceFee>'+(Tran.TransactionConvenienceFee*100).setscale(0)+'</TransactionConvenienceFee>';
                    if(Tran.ChargeDate!=''){
                    TransactionDetails+='<ChargeDate>'+Tran.ChargeDate+'</ChargeDate>';
                    }
                    if(TransactionCustomParameters!=null){
                    TransactionDetails+=TransactionCustomParameters;
                    }
                    TransactionDetails+='</Transaction>';
            }
 //Transaction node end
 
  
//Generating xml
            global string xmlfile{get;set;}
            global void getgeneratexml(PaaS_Class xmlstring){

                    xmlfile='<CnPAPI xmlns="urn:APISchema.xsd">';
  
                    xmlfile+='<Version>12</Version>'; 
  
xmlfile+='<Engine>';
xmlfile+='<Request>';
     
xmlfile+=Operation;
      
xmlfile+=Authentication;
xmlfile+='<Order>';
xmlfile+=Order;
xmlfile+='<CardHolder>';
xmlfile+=BillingInformation;
xmlfile+=BillingAddress;

xmlfile+=PaymentMethod;
if(CardHolderCustomParameters!=null){
xmlfile+=CardHolderCustomParameters;
}
xmlfile+='</CardHolder>';
            xmlfile+=Items;
             xmlfile+=receipt;
            xmlfile+=TransactionDetails;
      xmlfile+='</Order>';
    xmlfile+='</Request>';
  xmlfile+='</Engine>';
xmlfile+='</CnPAPI>';
xmlfile=xmlfile.replace('null','');
}

global integer TransactionResultCode {get;set;}//To display error code
global string ErrorData{get;set;}//To display error in text.
global string AdditionalInfo{get;set;}//To display error in detail.
global string TransactionNumber {get;set;} // To read transaction number
global string VaultGUID {get;set;}// To read VaultGUID
global string GatewayTransactionNumber {get;set;}
global string AuthorizationCode {get;set;}

global void Send_Transaction_api(string xmlfile){

PaaS_Cloud.basicHttpEndpoint  objpaymentservice = new PaaS_Cloud.basicHttpEndpoint(); 
         objpaymentservice.timeout_x = 60000;        
         PaaS_Cloud_Response.echoData data = objpaymentservice.Echo(xmlfile);       
         PaaS_Cloud_Response.ccTransactionResult transResult = objpaymentservice.Operation(xmlfile);
         
         TransactionResultCode=transResult.ResultCode;
         ErrorData=transResult.ResultData;
         AdditionalInfo = transResult.AdditionalInfo;
         TransactionNumber=transResult.TransactionNumber;
         VaultGUID=transResult.VaultGUID;
         GatewayTransactionNumber=transResult.GatewayTransactionNumber;
         AuthorizationCode=transResult.AuthorizationCode;
}

}