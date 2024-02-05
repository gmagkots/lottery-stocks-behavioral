/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : normality_tests                                                         */
/* Summary : Uses PROC UNIVARIATE to perform goodness-of-fit and hypothesis tests    */
/*           of the empirical distribution function compared to the normal           */
/*           distribution.                                                           */
/* Input   : The main data set for all public common shares that are traded on both  */
/*           given cross-section points.                                             */
/* Output  : A data set containing selected PROC UNIVARIATE output.                  */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Date    : August 2012                                                             */
/*                                                                                   */
/* ********************************************************************************* */

%macro normality_tests;

    /* combine the extreme portfolios in a single data set */
    proc univariate data=&data_extreme /*(where=(stock_returns < 100))*/
        /* normaltest */
        alpha=&alpha; /* mu0=&mu0; */
        class portfolio;
        var stock_returns;
        histogram stock_returns /
            normal
            noplot;
        output out=&data_test
            kurtosis = sample_kurtosis
            mean = sample_mean
            skewness = sample_skewness
            var = sample_variance
            stdmean = sample_mean_standard_error
            median = sample_median
            normaltest = normality_test_statistic
            probn = normality_test_p_value;
    run;

    proc npar1way data=&data_extreme /*(where=(stock_returns < 100))*/ edf;
        class portfolio;
        var stock_returns;
        exact edf / mc;
    run;

    /* print data details when in debugging mode */
    %if (&debug_mode) %then %debug(&data_test);;

%mend normality_tests;
