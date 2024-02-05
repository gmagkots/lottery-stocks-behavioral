/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : estimate_returns                                                        */
/* Summary : Auxiliary macro that estimates the returns for each stock.              */
/* Output  : The main data set for all public common shares that are traded on both  */
/*           given cross-section points.                                             */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Created : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro estimate_returns;

    data &data_main._view (drop=date prc shrout bkvlps csho market_to_book)
        / view=&data_main._view;
        set crsp_compustat;
        by permno;
        retain /*cross_section_1*/
               price_1
               shrout_1
             /*csho_1 */
               bkvlps_1
               market_to_book_1;

        if first.permno then
            do;
            /* retain the values if the first record is read */
              /*cross_section_1  = date;*/
                price_1          = prc;
                shrout_1         = shrout;
              /*csho_1           = csho;*/
                bkvlps_1         = bkvlps;
                market_to_book_1 = market_to_book;
            end;
        else if not first.permno and not last.permno then
            /* print the stock IDs that have more than two recors */
            put "Problem for permno " permno;
        else if last.permno then
            do;
            /* output all variables and returns after the second record is read */
              /*cross_section_2  = date;*/
                price_2          = prc;
                shrout_2         = shrout;
              /*csho_2           = csho;*/
                bkvlps_2         = bkvlps;
                market_to_book_2 = market_to_book;
                stock_returns    = (price_2 - price_1) / price_1 * 100;
                output;
            end;

        /* label the new variables */
        label stock_returns = 'Stock Returns (%)'
          /*cross_section_1  = 'Initial cross-section point'
            cross_section_2  = 'Final cross-section point'*/
            price_1          = 'Initial stock price'
            price_2          = 'Final stock price'
            shrout_1         = 'Initial Outstanding shares at CSP1'
            shrout_2         = 'Final Outstanding shares at CSP2'
          /*csho_1           = 'Outstanding shares on initial fiscal year end'
            csho_2           = 'Outstanding shares on final fiscal year end'*/
            bkvlps_1         = 'Initial book value per share'
            bkvlps_2         = 'Final book value per share'
            market_to_book_1 = 'Initial market-to-book ratio'
            market_to_book_2 = 'Final market-to-book ratio'
            ;
    run;

    /* sort the main output file by a M/B ratio */
    proc sort data=&data_main._view out=&data_main;
        by market_to_book_1;
    run;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %debug(&data_main);;

%mend estimate_returns;
