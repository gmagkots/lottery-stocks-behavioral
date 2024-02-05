/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : modify_market_to_book                                                   */
/* Summary : Auxiliary macro that modifies the calculated market to book ratio from  */
/*           M/B = MV_CRSP(t)/BV_COMP(t-1) to                                        */
/*           M/B = MV_CRSP(t)/BV_COMP(t-1) * (MV_COMP(t-1)/MV_CRSP(t-1))             */
/*           where MV, BV are Market Value (stock price times outstanding shares)    */
/*           and firm's Book Value (stock price times outstanding shares), and times */
/*           t and t-1 correspond to the chosen cross section point and the most     */
/*           recent past fiscal-year-end date respectively. The suffixes indicate    */
/*           the data source.                                                        */
/*                                                                                   */
/* Note    : The multiplying factor aims to reduce the systematic error introduced   */
/*           by combining data from different time periods between COMPUSTAT and     */
/*           CRSP. The correction may be significant for cases where firms have more */
/*           than one class of stocks, with certain classes not traded (class B) and */
/*           hence, not included in CRSP data.                                       */
/*           See http://guan.dk/market-value-equity                                  */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Date    : February 2013                                                           */
/*                                                                                   */
/* ********************************************************************************* */

%macro modify_market_to_book;

    /* rename the data view containing the initial market to book ratio */
    proc datasets;
        change crsp_compustat=crsp_compustat_old;
    run;

    /* create a temporary data view with the modified market to book ratio.
       Include a few CRSP dates prior to the fiscal-year-end date to ensure
       that at least one will be found without missing data. */
    proc sql;
        create view crsp_compustat_multiple_dates as
            select i.permno, i.tic, i.date, i.datadate,
                   i.prc, i.shrout, i.bkvlps, i.prcc_f, i.csho,
                  (i.market_to_book *
                   (i.csho*1e3*i.prcc_f)/(abs(dsf.prc)*dsf.shrout) ) as
                   market_to_book label='Market to book ratio', i.conm
            from crsp_compustat_old as i, crsp.dsf as dsf
            /* the date filter includes a few dates prior to the fiscal-year-end
               date in COMPUSTAT, to avoid missing data in CRSP on that date */
            where i.permno = dsf.permno and
                  0 <= datdif(dsf.date,i.datadate,'actual') <= 3

            /* group by permno, and order (sort) by permno and date to avoid
               upredictable behavior from sql */
            group by i.permno
            order by i.permno, i.date;
    quit;

    /* overwrite the initial data view and include a single date for each
       cross-section point */
    data crsp_compustat_single_dates / view=crsp_compustat_single_dates;
        do until (last.date);
            set crsp_compustat_multiple_dates;
            by permno date;
        end;
    run;
    proc sql;
        create view crsp_compustat as
            select * from crsp_compustat_single_dates as i
            group by i.permno
            having freq(i.permno) = 2
            order by i.permno, i.date;
    quit;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %debug(crsp_compustat);;

%mend modify_market_to_book;
