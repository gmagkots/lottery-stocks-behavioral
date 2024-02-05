/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : filter_crsp_links                                                       */
/* Summary : Auxiliary macro that creates a view with the desired CRSP data and      */
/*           CRSP links to COMPUSTAT.                                                */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Created : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro filter_crsp_links;

    proc sql;
        create view crsp_dsf_dsfhdr_ccm as
            /* keep only identifiers, dates, prices (absolute value) and outstanding
               shares. In addition, use SELECT DISTINCT to invoke an internal sort
               and remove duplicate records stemming from multiple link dates in the
               CCM link table. These duplicates arise (most likely) due to M&As. 
               We want to include such stocks in our analysis, but we need to
               remove the duplicate records. */
            select DISTINCT dsf.permno, dsf.date, ccm.gvkey, ccm.liid,
                   abs(dsf.prc) as prc label='Stock price', dsf.shrout

            /* query from DSF, DSFH, and CCM link table in CRSP */
            from crsp.dsf as dsf, crsp.dsfhdr as hdsf,
                 crsp.ccmxpf_linktable as ccm

            /* merge by common identifiers and specify filters:
                1. only two cross-section points (dates in DSF)
                2. choose only Ordinary Common Shares (share codes '10','11')
                3. include only certain link types ("LC", "LU", "LS", "LN")
                4. exclude dummy IIDs (existing company, non-existent security)
                5. sanity check for price (allow negative for bid/offer average)
                6. sanity check for outstanding shares
                7. market cap upper and lower limits */
            where dsf.permno = hdsf.permno and
                  dsf.permno = ccm.lpermno and
                 (dsf.date = &start_date or dsf.date = &end_date) and
                  hdsf.hshrcd in (10,11) and
                  ccm.linktype in ("LC", "LU", "LS", "LN") and
                  substr(ccm.liid,3,1) ^= 'X' and
                  abs(dsf.prc) > 0 and
                  dsf.shrout > 0 and
                  abs(dsf.prc)*dsf.shrout < &market_cap_upper_limit and
                  abs(dsf.prc)*dsf.shrout > &market_cap_lower_limit

            /* group by permno to exclude records that appear only on one cross
               section point (liquidated companies probably). Allow an even number
               of records for each permno, to include stocks from M&A events. */
            group by dsf.permno
            having mod(freq(dsf.permno),2) = 0

            /* sort by permno and then by cross-section point (date) */
            order by dsf.permno, dsf.date;
    quit;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %debug(crsp_dsf_dsfhdr_ccm);;

%mend filter_crsp_links;
