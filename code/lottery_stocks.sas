/* ********************************************************************************* */
/* ************************** STOCKS WITH LOTTERY PAYOFFS ************************** */
/* ********************************************************************************* */
/*                                                                                   */
/* Program : lottery_stocks                                                          */
/* Summary : Filters the extreme growth and value stocks within a given period to    */
/*           focus on behavioral aspects of stocks with lottery-style payoffs.       */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Date    : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

/*------------------  use this part if using SAS/Connect-----------------
  %let wrds = wrds.wharton.upenn.edu 4016;
  options comamid=TCP remote=WRDS;
  signon username=_prompt_;
  rsubmit;
---------------------------------------------------------------------- */

/* system options */
options nodate nocenter nonumber nosource ps=max ls=max;
options sasautos = ('./macros', sasautos) mautosource;
/* options spool macrogen symbolgen mprint mprintnest mlogic; */

/* define the output directories */
libname data_dir './data';
%let plot_dir = ./plots/;

/* define and run the main driver macro */
%macro lottery_stocks;

/* run-mode options */

    /* main controls (0 for false, else is true) */
    %let collect_data   = 01;
    %let modify_output  = 0;
    %let make_plots     = 01;
    %let test_normality = 0;
    %let debug_mode     = 0;

    /* cross-section points (dates) */
    %let start_date = %sysfunc(mdy(02,17,1993));
    %let end_date   = %sysfunc(mdy(02,18,1998));

    /* data filtering options */
    %let market_to_book_modification = 01;
    %let growth_portfolio_size = 300;
    %let value_portfolio_size  = 300;
    %let rank_variable = market_to_book_1;
    %let penny_stock_price_threshold = 10;
    %let market_cap_upper_limit = 1e12;
    %let market_cap_lower_limit = 1e0;

    /* plot options */
    %let ods_destination  = pdf;
    %let upper_percentile = 5;
    %let table_reference_height = 80;
    %let key_ticker_list  = ('IBM', 'INTC', 'MSFT',
                             'AAPL', 'CSCO', 'HPQ', 'DELL');

    /* normality test options (growth first, value second)
       alpha: confidence interval (probability of Type I error)
       mu0  : population mean for null hypothesis */
    %let alpha = 0.01;
    %let mu0   = 8.13697917;

/* do not modify the lines below */

    /* major data set and file names */
    %let suffix1   = %sysfunc(PutN(&start_date,date9.));
    %let suffix2   = %sysfunc(PutN(&end_date,date9.));

    %let data_main   = data_&suffix1._&suffix2;
    %let data_growth = growth_&suffix1._&suffix2;
    %let data_value  = value_&suffix1._&suffix2;
    %let data_growth_mod = &data_growth._modified;
    %let data_value_mod  = &data_value._modified;

    %let data_extreme = data_dir.growth_value_&suffix1._&suffix2;
    %let data_test    = data_dir.normal_test_&suffix1._&suffix2;
    %let data_edf_QQ  = data_dir.returns_QQ_&suffix1._&suffix2;

    /* get the data from CRSP and COMPUSTAT */
    %if (&collect_data) %then %merge_crsp_comp_data;

    /* modify the extreme growth and value portfolios */
    %if (&modify_output) %then %modify_extreme_portfolios;

    /* plot the results */
    %if (&make_plots) %then %plot_basic;

    /* perform normality tests */
    %if (&test_normality) %then %normality_tests;

%mend lottery_stocks;

%lottery_stocks;

/*------------------  use this part if using SAS/Connect-----------------
  endrsubmit;
  signoff;
---------------------------------------------------------------------- */
