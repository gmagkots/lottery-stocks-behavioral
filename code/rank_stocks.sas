/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : rank_stocks                                                             */
/* Summary : Auxiliary macro that creates the extreme value and extreme growth       */
/*           portfolios by proper choice of market to book ratios from the main      */
/*           output file.                                                            */
/* Input   : The main data set for all public common shares that are traded on both  */
/*           given cross-section points.                                             */
/* Output  : A data set with the combined information of the extreme value and       */
/*           extreme growth stock portfolios.                                        */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Date    : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro rank_stocks;

    /* create the extreme growth and value portfolios */
    data &data_value &data_growth;
        set &data_main nobs=total_records;
        by &rank_variable;

        if (_N_ <= &value_portfolio_size) then
            output &data_value;
        if (_N_ >= total_records - &growth_portfolio_size + 1) then
            output &data_growth;
    run;

    /* combine the extreme portfolios in a single data set */
    data &data_extreme;
        set &data_value (in=v) &data_growth (in=g);
        by &rank_variable;

        if v then portfolio='value '; else portfolio='growth';
    run;

    /* sort each of the extreme growth and value portfolios by returns
       and merge the sorted stock returns for the QQ plot */
    proc sort data=&data_growth out=data_growth_return_sort
        (keep=stock_returns tic conm);
        by stock_returns;
    run;
    proc sort data=&data_value out=data_value_return_sort
        (keep=stock_returns tic conm);
        by stock_returns;
    run;
    data &data_edf_QQ;
        /*retain diagonal;*/

        merge data_growth_return_sort (rename=(stock_returns=stock_returns_growth
            tic=ticker_growth conm=company_growth))
              data_value_return_sort (rename=(stock_returns=stock_returns_value
            tic=ticker_value  conm=company_value));

        /*diagonal = min(stock_returns_growth,stock_returns_value);
        if (_N_ = &growth_portfolio_size) then
            diagonal = max(stock_returns_growth,stock_returns_value);*/

        percentile = _N_/min(&growth_portfolio_size,&value_portfolio_size)*100;

        label
            percentile = 'Percentile that the stock belongs in'
            stock_returns_growth = 'Growth Stock Returns (%)'
            stock_returns_value  = 'Value Stock Returns (%)'
            ticker_growth = 'Growth Stock Symbol'
            ticker_value  = 'Value Stock Symbol';
    run;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %do;
        %debug(&data_value);
        %debug(&data_growth);
        %debug(&data_extreme);
        /* %debug(&data_edf_QQ); */
    %end;

    /* print the empirical distribution QQ data */
    %debug(&data_edf_QQ);

%mend rank_stocks;
