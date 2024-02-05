/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : modify_extreme_portfolios                                               */
/* Summary : Modifies the extreme value and extreme growth portfolios. The           */
/*           modifications are case-dependent, so this macro changes frequently.     */
/* Input   : The extreme growth and value protfolios                                 */
/* Output  : Two extreme growth and value protfolios modified                        */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Date    : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro modify_extreme_portfolios;

    data &data_value_mod;
        set &data_value (where=(stock_returns < 100));
        by &rank_variable;
    run;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %do;
        %debug(&data_value_mod);
        /*%debug(&data_growth_mod);*/
    %end;

%mend modify_extreme_portfolios;
