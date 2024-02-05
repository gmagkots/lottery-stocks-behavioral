/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : merge_crsp_comp_data                                                    */
/* Summary : Merges data from the Daily Stock File (DSF) and its header (DSFHDR) in  */
/*           CRSP with the Fundamental Annual (FUNDA) data in COMPUSTAT. The linking */
/*           set CCMXPF_LINKTABLE from CRSP is used to properly link the libraries.  */
/*           Firms that have been liquidated in between the given cross-section      */
/*           points are excluded, but care is taken to include events such as M&As   */
/*           that result in changes to data headers (tickers, names, etc). In        */
/*           addition, penny stocks (price below a set threshold) are excluded.      */
/* Input   : 1) The begin date marking the first cross section point,                */
/*           2) the end date marking the second cross section point, and             */
/*           3) a logical to determine normal or debug running mode.                 */
/* Output  : A data set including market to book ratios and returns for all public   */
/*           common shares that are traded on both given cross-section points.       */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Date    : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro merge_crsp_comp_data;

    /* filter the desired CRSP data and links to COMPUSTAT */
    %filter_crsp_links;

    /* calculate the M/B ratios for all stocks */
    %estimate_market_to_book;

    /* Correct the market to book ratio if desired */
    %if (&market_to_book_modification) %then %modify_market_to_book;

    /* compact stock data to single record and calculate the returns */
    %estimate_returns;

    /* extract the growth and value stocks */
    %rank_stocks;

%mend merge_crsp_comp_data;
