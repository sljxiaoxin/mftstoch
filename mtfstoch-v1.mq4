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
extern int       intSL           = 25;            //止损点数，不用加0
extern double    distance        = 5;   //加仓间隔点数

extern double    levelTriggerHigh = 90;
extern double    levelTriggerLow  = 10;
extern double    levelOverBuy     = 80;
extern double    levelOverSell    = 20;

extern bool      isTrailingStop   = true;


int digits;
int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1,CheckTimeM5;
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
     
     //M1产生交易
     if(CheckTimeM1==iTime(NULL,PERIOD_M5,0)){
         
     } else {
         ////////////////////////// 
         string sig = signal();
         if(strSignal == "none"){
            if(sig == "buy"){
               strSignal = sig;
               TriggerBuyNumber = 0;
            }
            if(sig == "sell"){
               strSignal = sig;
               TriggerSellNumber = 0;
            }
         }
         if(strSignal == "buy"){
            if(sig == "buy"){
               TriggerBuyNumber += 1;
            }
            if(sig == "sell"){
               strSignal = sig;
               TriggerSellNumber = 0;
            }
            if(sig == "none"){
               TriggerBuyNumber += 1;
            }
         }
         if(strSignal == "sell"){
            if(sig == "buy"){
               strSignal = sig;
               TriggerBuyNumber = 0;
            }
            if(sig == "sell"){
               TriggerSellNumber += 1;
            }
            if(sig == "none"){
               TriggerSellNumber += 1;
            }
         }
         CheckTimeM1 = iTime(NULL,PERIOD_M5,0);
         checkProtected();
         checkEntry();
     }
 }


 //信号检测
string signal()
{
   double fast[3];
   int j;
   for( j=0;j<3;j++) {
      fast[j] = iStochastic(NULL, 0, 14, 1, 1, MODE_SMA, 0, MODE_MAIN, j+1);
   }
   string t = "none";
   if(fast[0] < levelTriggerLow){
        t = "buy";
   }
   if(fast[0] >levelTriggerHigh){
        t = "sell";
   }
   return t;
}

//检测entry
void checkEntry(){
   if(objCTradeMgr.Total()>0)return ;
   double stochM15_3,stochM15_2,stochM15_1;
   stochM15_3 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 3);
   stochM15_2 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   stochM15_1 = iStochastic(NULL, PERIOD_M15, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stochM5_1 = iStochastic(NULL, 0, 14, 1, 1, MODE_SMA, 0, MODE_MAIN, 1);
   double stochH4_1 = iStochastic(NULL, PERIOD_H4, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   if(strSignal == "buy"){
      if(stochM15_2<stochM15_1){
         if(stochM15_1 < 60 && stochM5_1 >23.6 && stochH4_1<80){
            Print(" buy stochM15_1=",stochM15_1,";stochM15_2=",stochM15_2,";stochM15_3=",stochM15_3);
            objCTradeMgr.Buy(Lots, intSL, intTP, "up");
         }
      }
   }
   
   if(strSignal == "sell"){
      if(stochM15_2>stochM15_1){
         if(stochM15_1 > 40 && stochM5_1 <76.4 && stochH4_1>20){
            objCTradeMgr.Sell(Lots, intSL, intTP, "down");
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
   
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY){
            if(strSignal == "sell" && TriggerSellNumber>4 && stochM15_2>stochM15_1){
               tradeTicket = OrderTicket();
               Print("close buy id=>",tradeTicket,";stochM15_1=",stochM15_1,";stochM15_2=",stochM15_2,";stochM15_3=",stochM15_3);
               objCTradeMgr.Close(tradeTicket);
            }
         }
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL){
            if(strSignal == "buy" && TriggerBuyNumber>4 && stochM15_2<stochM15_1){
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
               if(myStopLoss - openPrice <0 && Close[1] - openPrice >= 7*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               if(myStopLoss - openPrice <0 && Close[1] - openPrice >= 14*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               
            }
            if(OrderType() == OP_SELL){
              // dt = OrderOpenTime();
              // dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               
               if(openPrice - myStopLoss <0 && openPrice - Close[1]  > 7*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               if(openPrice - myStopLoss <0 && openPrice - Close[1]  > 14*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
            }

         }
      }
     }
   }
}