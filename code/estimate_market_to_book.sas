/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : estimate_market_to_book                                                 */
/* Summary : Auxiliary macro that estimates the market-to-book ratio for each stock. */
/*                                                                                   */
/* Note    : Since FUNDA is used, datadate reflects the fiscal year end date, not    */
/*           any other quarterly reporting period.                                   */
/*                                                                                   */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Created : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro estimate_market_to_book;

    proc sql;
        /* create the market to book ratio dynamically. Allow negative book values
           but force positive values for the market to book ratio. */
        create view crsp_compustat as
            select c.permno, f.tic, c.date, f.datadate, /*f.gvkey, f.iid, */
                   c.prc, c.shrout, f.bkvlps, f.prcc_f, f.csho,
                   (c.prc*c.shrout / (abs(f.bkvlps)*f.csho*1e3)) as
                   market_to_book label='Market to book ratio', f.conm

            /* query from the previous data set and COMPUSTAT FUNDA */
            from crsp_dsf_dsfhdr_ccm as c, comp.funda as f

            /* merge by common identifiers and specify filters:
                1. choose report dates that are closest to the cross section points
                2. require a specific report format to eliminate duplicates in FUNDA
                3. require positive number of outstanding shares
                4. exclude penny stocks
                5. allow for negative book values */
            where c.gvkey = f.gvkey and
                  c.liid  = f.iid and
                  0 <= datdif(f.datadate,c.date,'actual') < 365 and
                  f.indfmt = 'INDL' and
                  f.consol = 'C' and
                  f.popsrc = 'D' and
                  f.datafmt = 'STD' and
                  f.csho > 0 and
                  c.prc > &penny_stock_price_threshold and
                  f.prcc_f > &penny_stock_price_threshold and
                  f.bkvlps ^= .

            /* allow only two records per permnno, to eliminate single records (from
               changes in fiscal year end (fyr) that happen to be in proximity to one
               of the cross section points) and multiple records from errors between 
               CRSP and COMPUSTAT (single PERMNO corresponding to multiple GVKEYs) */
            group by c.permno
            having freq(c.permno) = 2

            /* sort by permno and then by cross-section point (date) */
            order by c.permno, c.date;
    quit;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %debug(crsp_compustat);;

%mend estimate_market_to_book;
