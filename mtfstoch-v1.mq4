//+------------------------------------------------------------------+
//|     基于mftstoch
//
//+------------------------------------------------------------------+
#property copyright "xiaoxin003"
#property link      "yangjx009@139.com"
#property version   "1.0"
#property strict

#include <Arrays\ArrayInt.mqh>
#include "inc\dictionary.mqh" //keyvalue数据字典类
#include "inc\trademgr.mqh"   //交易工具类
#include "inc\citems.mqh"     //交易组item


extern int       MagicNumber     = 201807;
extern double    Lots            = 0.05;
extern int       intTP           = 120;
extern int       intSL           = 15;            //止损点数，不用加0
extern double    distance        = 5;   //加仓间隔点数

extern double    levelTriggerHigh = 90;
extern double    levelTriggerLow  = 10;
extern double    levelOverBuy     = 80;
extern double    levelOverSell    = 20;

extern bool      isTrailingStop   = true;


int digits;
int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM15,CheckTimeM5,CheckTimeM1;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;

int TriggerBuyNumber = -1; //最新buy信号已经过柱子数量
int TriggerSellNumber = -1; //

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   Print("begin");
   digits=Digits;
   if(Digits==2 || Digits==4) Pip = Point;
   else if(Digits==3 || Digits==5) Pip = 10*Point;
   else if(Digits==6) Pip = 100*Point;
   if(objDict == NULL){
      objDict = new CDictionary();
      objCTradeMgr = new CTradeMgr(MagicNumber, Pip, NumberOfTries, Slippage);
   }
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("deinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
string strSignal = "none";
void OnTick()
{
     if(isTrailingStop)MoveTrailingStop();
     //updateLastTicketStatus();
     subPrintDetails();
     
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         
     } else {
         checkEntry();
         CheckTimeM1 = iTime(NULL,PERIOD_M1,0);
     }
     
     if(CheckTimeM15==iTime(NULL,PERIOD_M15,0)){
         
     } else {
         string sig = signal();
         if(sig != "none"){
            strSignal = sig;
         }
         CheckTimeM15 = iTime(NULL,PERIOD_M15,0);
     }
     
     if(CheckTimeM5==iTime(NULL,PERIOD_M5,0)){
         
     } else {
         ////////////////////////// 
         CheckTimeM5 = iTime(NULL,PERIOD_M5,0);
         checkProtected();
     }
 }

string signal()
{
   double stochM15[3];
   int j;
   for( j=0;j<3;j++) {
      stochM15[j] = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, j+1);
   }
   double stochM5;
   string t = "none";
   if(stochM15[0]>stochM15[1] && stochM15[2]>stochM15[1]){
      for( j=2;j<20;j++) {
         stochM5 = iStochastic(NULL, PERIOD_M5, 14, 1, 1, MODE_SMA, 0, MODE_MAIN, j+1);
         if(stochM5 <=levelTriggerLow){
            t = "long";
         }
      }
   }
   if(stochM15[0]<stochM15[1] && stochM15[2]<stochM15[1]){
      for( j=2;j<20;j++) {
         stochM5 = iStochastic(NULL, PERIOD_M5, 14, 1, 1, MODE_SMA, 0, MODE_MAIN, j+1);
         if(stochM5 >=levelTriggerHigh){
            t = "short";
         }
      }
   }
   return t;
}

void checkEntry(){
   if(objCTradeMgr.Total()>0)return ;
   
	double stochM1_1 = iStochastic(NULL, PERIOD_M1, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
	
   double stochM5_1 = iStochastic(NULL, 0, 14, 1, 1, MODE_SMA, 0, MODE_MAIN, 1);

   
   double stochM15_1 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stochM15_2 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   double stochM15_3 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 3);
   
   double stochM30_1 = iStochastic(NULL, PERIOD_M30, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stochM30_2 = iStochastic(NULL, PERIOD_M30, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   
   double stochH1_1 = iStochastic(NULL, PERIOD_H1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stochH1_2 = iStochastic(NULL, PERIOD_H1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);

   double stochH4_1 = iStochastic(NULL, PERIOD_H4, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stochH4_2 = iStochastic(NULL, PERIOD_H4, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   

   if(strSignal == "long" && stochM1_1<30){
      if(stochH4_1<=20){
         if(stochM15_1>20 && stochM30_1>stochM30_2 && stochH1_1>stochH1_2){
             objCTradeMgr.Buy(Lots, intSL, intTP, "long_1");
         }
      }else if(stochH4_1>20 && stochH4_1<80){
         if(stochM15_1>stochM15_2 && stochM30_1>stochM30_2){
             objCTradeMgr.Buy(Lots, intSL, intTP, "long_2");
         }
      }else if(stochH4_1>80){
         if(stochM15_1>stochM15_2 && stochM30_1>stochM30_2 && stochH1_1>stochH1_2){
             objCTradeMgr.Buy(Lots, intSL, intTP, "long_3");
         }
      }
   }
   
   if(strSignal == "short" && stochM1_1>70){
      if(stochH4_1>=80){
         if(stochM15_1<80 && stochM30_1<stochM30_2 && stochH1_1<stochH1_2){
             objCTradeMgr.Sell(Lots, intSL, intTP, "short_1");
         }
      }else if(stochH4_1>20 && stochH4_1<80){
         if(stochM15_1<stochM15_2 && stochM30_1<stochM30_2){
             objCTradeMgr.Sell(Lots, intSL, intTP, "short_2");
         }
      }else if(stochH4_1<20){
         if(stochM15_1<stochM15_2 && stochM30_1<stochM30_2 && stochH1_1<stochH1_2){
             objCTradeMgr.Sell(Lots, intSL, intTP, "short_2");
         }
      }
   }
}

void checkProtected(){
   if(objCTradeMgr.Total()<=0)return ;
   int tradeTicket;
   double stochM15_3,stochM15_2,stochM15_1;
   stochM15_3 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 3);
   stochM15_2 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   stochM15_1 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stochM30_2 = iStochastic(NULL, PERIOD_M30, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   double stochM30_1 = iStochastic(NULL, PERIOD_M30, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY){
            if(strSignal == "short"  && stochM30_2>stochM30_1 && stochM15_2>stochM15_1){
               tradeTicket = OrderTicket();
               Print("close buy id=>",tradeTicket,";stochM15_1=",stochM15_1,";stochM15_2=",stochM15_2,";stochM15_3=",stochM15_3);
               objCTradeMgr.Close(tradeTicket);
            }
         }
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL){
            if(strSignal == "long" && stochM30_2<stochM30_1  && stochM15_2<stochM15_1){
               tradeTicket = OrderTicket();
               Print("close sell id=>",tradeTicket,";stochM15_1=",stochM15_1,";stochM15_2=",stochM15_2,";stochM15_3=",stochM15_3);
               objCTradeMgr.Close(tradeTicket);
            }
         }
      }
   }
}



int getSL(){
  return intSL;
}

int getTP(){
  return intTP;
}

void subPrintDetails()
{
   //
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   //sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   sComment = sComment + sp;
   sComment = sComment + sp;
   sComment = sComment + "strSignal=" + strSignal +";"+ NL;
   
    
   
   Comment(sComment);
}

void MoveTrailingStop(){
   if(isTrailingStop){
     double newSL;
     double openPrice,myStopLoss;
     datetime dt,dtNow;
     for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {     
         if(OrderMagicNumber() == MagicNumber  && OrderSymbol() == Symbol()){

            if(OrderType() == OP_BUY ){
               //dt = OrderOpenTime();
               //dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               
               //盈利超过2.5Pip则向上提止损
               if(myStopLoss - openPrice < 8*Pip && Bid - openPrice >= 25*Pip){
                  newSL = openPrice + 8*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(myStopLoss - openPrice <5*Pip && Bid - openPrice >= 14*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 10*Pip){
                  newSL = openPrice + 2*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 7*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               
               
               
            }
            if(OrderType() == OP_SELL){
              // dt = OrderOpenTime();
              // dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               if(openPrice - myStopLoss <8*Pip && openPrice - Ask  > 25*Pip){
                  newSL = openPrice - 8*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(openPrice - myStopLoss <5*Pip && openPrice - Ask  > 14*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(openPrice - myStopLoss <0 && openPrice - Ask  > 10*Pip){
                  newSL = openPrice -2*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(openPrice - myStopLoss <0 && openPrice - Ask  > 7*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               
            }

         }
      }
     }
   }
}