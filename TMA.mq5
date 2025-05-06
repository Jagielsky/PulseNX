#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 3
#property indicator_label1 "Middle band"
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 clrNONE, clrNONE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_label2 "Upper band"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrWhite
#property indicator_style2 STYLE_DOT
#property indicator_label3 "Lower band"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrWhite
#property indicator_style3 STYLE_DOT

enum enPrices
{
    pr_close,
    pr_open,
    pr_high,
    pr_low,
    pr_median,
    pr_typical,
    pr_weighted,
    pr_average,
    pr_haclose,
    pr_haopen,
    pr_hahigh,
    pr_halow,
    pr_hamedian,
    pr_hatypical,
    pr_haweighted,
    pr_haaverage
};

input int HalfLength = 12;
input enPrices Price = pr_weighted;
input int AtrPeriod = 100;
input double AtrMultiplier = 2.0;

double tmac[];
double tmau[];
double tmad[];
double colorBuffer[];

int OnInit()
{
    SetIndexBuffer(0, tmac, INDICATOR_DATA);
    SetIndexBuffer(1, colorBuffer, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(2, tmau, INDICATOR_DATA);
    SetIndexBuffer(3, tmad, INDICATOR_DATA);

    IndicatorSetString(INDICATOR_SHORTNAME, " TMA centered (" + string(HalfLength) + ")");
    return (0);
}

double prices[];

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if (ArraySize(prices) != rates_total)
        ArrayResize(prices, rates_total);
    for (int i = (int)MathMax(prev_calculated - 1, 0); i < rates_total; i++)
        prices[i] = getPrice(Price, open, close, high, low, i, rates_total);
    for (int i = (int)MathMax(prev_calculated - HalfLength, 0); i < rates_total; i++)
    {
        double atr = 0;
        for (int j = 0; j < AtrPeriod && (i - j - 11) >= 0; j++)
            atr += MathMax(high[i - j - 10], close[i - j - 11]) - MathMin(low[i - j - 10], close[i - j - 11]);
        atr /= AtrPeriod;

        double sum = (HalfLength + 1) * prices[i];
        double sumw = (HalfLength + 1);
        for (int j = 1, k = HalfLength; j <= HalfLength; j++, k--)
        {
            if ((i - j) >= 0)
            {
                sum += k * prices[i - j];
                sumw += k;
            }
            if ((i + j) < rates_total)
            {
                sum += k * prices[i + j];
                sumw += k;
            }
        }
        tmac[i] = sum / sumw;
        if (i > 0)
        {
            colorBuffer[i] = colorBuffer[i - 1];
            if (tmac[i] > tmac[i - 1])
                colorBuffer[i] = 0;
            if (tmac[i] < tmac[i - 1])
                colorBuffer[i] = 1;
        }
        tmau[i] = tmac[i] + AtrMultiplier * atr;
        tmad[i] = tmac[i] - AtrMultiplier * atr;
    }
    return (rates_total);
}

double workHa[][4];
double getPrice(enPrices price, const double &open[], const double &close[], const double &high[], const double &low[], int i, int bars)
{
    if (price >= pr_haclose && price <= pr_haaverage)
    {
        if (ArrayRange(workHa, 0) != bars)
            ArrayResize(workHa, bars);

        double haOpen;
        if (i > 0)
            haOpen = (workHa[i - 1][2] + workHa[i - 1][3]) / 2.0;
        else
            haOpen = open[i] + close[i];
        double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
        double haHigh = MathMax(high[i], MathMax(haOpen, haClose));
        double haLow = MathMin(low[i], MathMin(haOpen, haClose));

        if (haOpen < haClose)
        {
            workHa[i][0] = haLow;
            workHa[i][1] = haHigh;
        }
        else
        {
            workHa[i][0] = haHigh;
            workHa[i][1] = haLow;
        }
        workHa[i][2] = haOpen;
        workHa[i][3] = haClose;
        switch (price)
        {
        case pr_haclose:
            return (haClose);
        case pr_haopen:
            return (haOpen);
        case pr_hahigh:
            return (haHigh);
        case pr_halow:
            return (haLow);
        case pr_hamedian:
            return ((haHigh + haLow) / 2.0);
        case pr_hatypical:
            return ((haHigh + haLow + haClose) / 3.0);
        case pr_haweighted:
            return ((haHigh + haLow + haClose + haClose) / 4.0);
        case pr_haaverage:
            return ((haHigh + haLow + haClose + haOpen) / 4.0);
        }
    }
    switch (price)
    {
    case pr_close:
        return (close[i]);
    case pr_open:
        return (open[i]);
    case pr_high:
        return (high[i]);
    case pr_low:
        return (low[i]);
    case pr_median:
        return ((high[i] + low[i]) / 2.0);
    case pr_typical:
        return ((high[i] + low[i] + close[i]) / 3.0);
    case pr_weighted:
        return ((high[i] + low[i] + close[i] + close[i]) / 4.0);
    case pr_average:
        return ((high[i] + low[i] + close[i] + open[i]) / 4.0);
    }
    return (0);
}
