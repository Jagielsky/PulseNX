#include <Trade\Trade.mqh>
CTrade trade;

enum enPrices
{
    pr_weighted
};

input int halfLength = 12; // TMA half length
input int atrPeriod = 100; // TMA atr period
input double atrMultiplier = 2.0; // TMA atr multiplier

input int kPeriod = 5; // Stoch K period
input int dPeriod = 3; // Stoch D period
input int slowing = 3; // Stoch slowing

input int period = 14; // ATR period
input double multiplier = 4.0; // ATR stop loss multiplier

int haHandle = INVALID_HANDLE;
int tmaHandle = INVALID_HANDLE;
int stochHandle = INVALID_HANDLE;
int atrHandle = INVALID_HANDLE;

double haHigh[], haLow[];
double tmaHigh[], tmaLow[];
double stoch[];
double atr[];

int OnInit()
{
    haHandle = iCustom(_Symbol, _Period, "Examples\\Heiken_Ashi");
    tmaHandle = iCustom(_Symbol, _Period, "TMA", halfLength, pr_weighted, atrPeriod, atrMultiplier);
    stochHandle = iStochastic(_Symbol, _Period, kPeriod, dPeriod, slowing, MODE_SMA, STO_LOWHIGH);
    atrHandle = iATR(_Symbol, _Period, period);

    if (haHandle == INVALID_HANDLE || tmaHandle == INVALID_HANDLE || stochHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
    {
        return (INIT_FAILED);
    }

    ArraySetAsSeries(haHigh, true);
    ArraySetAsSeries(haLow, true);
    ArraySetAsSeries(tmaHigh, true);
    ArraySetAsSeries(tmaLow, true);
    ArraySetAsSeries(stoch, true);
    ArraySetAsSeries(atr, true);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    if (haHandle != INVALID_HANDLE) IndicatorRelease(haHandle);
    if (tmaHandle != INVALID_HANDLE) IndicatorRelease(tmaHandle);
    if (stochHandle != INVALID_HANDLE) IndicatorRelease(stochHandle);
    if (atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
}

void OnTick()
{
    if (!newCandle()) return;
    
    MqlTick tick;
    if (!SymbolInfoTick(_Symbol, tick)) return;
    
    if (CopyBuffer(haHandle, 1, 1, 1, haHigh) != 1) return;
    if (CopyBuffer(haHandle, 2, 1, 1, haLow) != 1) return;
    if (CopyBuffer(tmaHandle, 2, 1, 1, tmaHigh) != 1) return;
    if (CopyBuffer(tmaHandle, 3, 1, 1, tmaLow) != 1) return;
    if (CopyBuffer(stochHandle, 0, 1, 1, stoch) != 1) return;
    if (CopyBuffer(atrHandle, 0, 1, 1, atr) != 1) return;
    
    static string signal = "none";
    static string position = "none";
    double entryPrice = 0.0;
    double stopLoss = 0.0;
    
    if (haHigh[0] >= tmaHigh[0] && stoch[0] >= 80)
    {
        signal = "sell";
    }
    else if (haLow[0] <= tmaLow[0] && stoch[0] <= 20)
    {
        signal = "buy";
    }
    
    if (signal == "sell" && position != "short")
    {
        if (position == "long") trade.PositionClose(_Symbol);
        
        entryPrice = tick.bid;
        stopLoss = entryPrice + (atr[0] * multiplier);
        
        if (trade.Sell(0.1, _Symbol, entryPrice, stopLoss))
        {
            signal = "none";
            position = "short";
        }
    }
    else if (signal == "buy" && position != "long")
    {
        if (position == "short") trade.PositionClose(_Symbol);
        
        entryPrice = tick.ask;
        stopLoss = entryPrice - (atr[0] * multiplier);
            
        if (trade.Buy(0.1, _Symbol, entryPrice, stopLoss))
        {
            signal = "none";
            position = "short";
        }
    }
}

bool newCandle()
{
    static datetime previousCandle = 0;
    datetime currentCandle = iTime(_Symbol, _Period, 0); 
    if (previousCandle != currentCandle)
    {
        previousCandle = currentCandle;
        return true;
    }
    return false;
}
