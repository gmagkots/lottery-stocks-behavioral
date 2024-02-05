/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : plot_basic                                                              */
/* Summary : Creates a few basic plots for the output data                           */
/* Input   : The time lag between trade and quote time (in seconds),                 */
/*           a logical for the output format (data set or a data view), and          */
/*           a logical to determine normal or debug running mode                     */
/* Output  : A data set (or data view) with the merged trade and quote data          */
/*                                                                                   */
/* Author  : Georgios Magkotsios                                                     */
/* Created : June 2012                                                               */
/*                                                                                   */
/* ********************************************************************************* */

%macro plot_basic;

    /* specify the annotation text */
    %let annotation_text = "Period: " 
        "%sysfunc(PutN(&start_date,mmddyy10.)) - "
        "%sysfunc(PutN(&end_date,mmddyy10.))";

    /* set the line thickness value */
    %let linethickness = 3px;

    /* close all destinations, including the default ones */
    ods _all_ close;

    /* set the orientation to landscape for the graphs */
    options orientation=landscape;

    /* modify some properties within the printer template */
    proc template;
        define style custom_style;
        parent = styles.printer;
        style GraphFonts from GraphFonts /
            'GraphDataFont' = ("<MTserif>, <serif>",9pt)
            'GraphValueFont' = ("<MTserif>, <serif>",14pt,bold)
            'GraphLabelFont' = ("<MTserif>, <serif>",16pt,bold)
            'GraphFootnoteFont' = ("<MTserif>, <serif>",13pt,bold)
            'GraphTitleFont' = ("<sans-serif>, <MTsans-serif>",18pt,bold)
            'GraphAnnoFont' = ("<MTserif>, <serif>",12pt,bold);
        style GraphAxisLines from GraphAxisLines /
            linethickness = &linethickness;
        style GraphWalls from GraphWalls /
            linethickness = &linethickness;
        style GraphOutlines from GraphOutlines /
            linethickness = &linethickness;
        style GraphFit from GraphFit /
            linethickness = &linethickness;
        style GraphFit2 from GraphFit2 /
            linethickness = &linethickness;
        style GraphDataDefault from GraphDataDefault /
            markersize    = 9px;
        end;
    run;

    /* create the annotation data set with ticker names (SAS 9.3 only) */

    data ticker_annotations;
        length function style color $ 8 text $ 25;
        retain line;
        set &data_edf_QQ end=_last_;

        if _N_ = 1 then line = int( - &upper_percentile/100 *
            min(&growth_portfolio_size,&value_portfolio_size) + 1);

        /* annotate a few selected stocks */
/*
        if ticker_value in &key_ticker_list then do;
            function = "arrow";
            x1 = stock_returns_growth - 12;
            y1 = stock_returns_value  + 12;
            x2 = stock_returns_growth - 3;
            y2 = stock_returns_value  + 3;
            linethickness = 3;
            shape = "barbed";
            drawspace = "datavalue";
            output;
            x1 = stock_returns_growth - 18;
            y1 = stock_returns_value  + 18;
            function = "text";
            label = trim(ticker_value) || " (v)";
            drawspace = "datavalue";
            width = 20;
            output;
        end;
        if ticker_growth in &key_ticker_list then do;
            function = "arrow";
            x1 = stock_returns_growth + 12;
            y1 = stock_returns_value  - 12;
            x2 = stock_returns_growth + 3;
            y2 = stock_returns_value  - 3;
            linecolor = "red";
            linethickness = 3;
            shape = "barbed";
            drawspace = "datavalue";
            output;
            x1 = stock_returns_growth + 18;
            y1 = stock_returns_value  - 18;
            function = "text";
            label =  "(g) " || trim(ticker_growth);
            drawspace = "datavalue";
            width = 20;
            output;
        end;
*/
        /* tabulate only an amount of high percentile points */
        if percentile >= (100 - &upper_percentile);

        line = line + 1;
        x1 = 106;
        y1 = int(&table_reference_height + 3*line);
        function = "text";
        label = trim(ticker_value);
        if ticker_value in &key_ticker_list then textcolor = "red";
        width = 10;
        output;
        x1 = 116;
        y1 = int(&table_reference_height + 3*line);
        function = "text";
        label = trim(ticker_growth);
        if ticker_growth in &key_ticker_list then textcolor = "red";
        width = 10;
        output;

        if (_last_) then do;
            line = line + 1;
            y1 = int(&table_reference_height + 3*line);
            x1 = 106;
            label="Value";
            textcolor = "black";
            output;
            x1=116;
            label="Growth";
            textcolor = "black";
            output;
            line = line + 1;
            width = 20;
            anchor = "top";
            y1 = int(&table_reference_height + 4*line);
            x1 = 112.5;
            label=cat("Upper ",&upper_percentile,"%");
            textcolor = "black";
            output;
        end;

    run;

    /* remove the default title added by PROC statements */
    ods noproctitle;

    /* set the ods graphics options */
    ods graphics on /
        reset=all
        /*width=10.5in*/
        /*height=7.8in*/
        /*height=7.1in*/
        width=12.5in /* SAS 9.3 */
        height=9.1in /* SAS 9.3 */
        border=off;


    /* histograms */

    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.growth_returns_histogram_&suffix1._&suffix2..pdf";
    proc sgplot data=&data_extreme (where=(portfolio='growth'));
        histogram stock_returns;
        density stock_returns;
        density stock_returns / type=kernel;
        title "Growth Stock Returns";
        footnote j=r &annotation_text;
        *inset &annotation_text / noborder position=topright;
    run;
    ods &ods_destination close;

    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.value_returns_histogram_&suffix1._&suffix2..pdf";
    proc sgplot data=&data_extreme (where=(portfolio='value'));
        histogram stock_returns;
        density stock_returns;
        density stock_returns / type=kernel;
        title "Value Stock Returns";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;
/**/

    /* Q-Q plots */

    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.growth_returns_QQplot_&suffix1._&suffix2..pdf";
    proc univariate data=&data_extreme (where=(portfolio='growth'))
        noprint;
        qqplot stock_returns / normal(mu=est sigma=est color=red w=3);
        title "Growth Stock Returns QQ Plot";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;

    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.value_returns_QQplot_&suffix1._&suffix2..pdf";
    proc univariate data=&data_extreme (where=(portfolio='value'))
        noprint;
        qqplot stock_returns / normal(mu=est sigma=est color=red w=3);
        title "Value Stock Returns QQ Plot";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;
/**/
    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.returns_QQ_&suffix1._&suffix2..pdf";
    proc sgplot data=&data_edf_QQ noautolegend
        sganno=ticker_annotations pad=(right=25%);
        scatter x=stock_returns_growth y=stock_returns_value;
        /*series x=diagonal y=diagonal / lineattrs=(color=blue pattern=1);*/
        lineparm x=0 y=0 slope=1 / lineattrs=(color=blue thickness=&linethickness);
        title "Value vs Growth Stock Returns QQ Plot";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;

    /* CDF plots */

    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.returns_CDF_&suffix1._&suffix2..pdf";
    proc univariate data=&data_extreme noprint;
        class portfolio;
        var stock_returns;
        cdfplot stock_returns / overlay;
        title "Growth vs Value Stocks Cumulative Distribution Functions";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;
/**/
    /* scatter plots */
/*
    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.combined_price_returns_&suffix1._&suffix2..pdf";
    proc sgplot data=&data_extreme;
        scatter x=price_1 y=stock_returns / group=portfolio;
        title "Returns vs Price for combined portfolio";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;

    ods &ods_destination style=custom_style BOOKMARKGEN=NO
        file="&plot_dir.combined_m2b_returns_&suffix1._&suffix2..pdf";
    proc sgplot data=&data_extreme;
        xaxis min=0 max=10;
        scatter x=market_to_book_1 y=stock_returns / group=portfolio;
        title "Returns vs M/B for combined portfolio";
        footnote j=r &annotation_text;
    run;
    ods &ods_destination close;
*/

    /* Close the graphics destination */
    ods graphics off;

%mend plot_basic;
