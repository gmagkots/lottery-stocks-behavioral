/* ********************************************************************************* */
/*                                                                                   */
/* Macro   : jarque_berra                                                            */
/* Summary : Auxiliary macro that prints the input data set with its contents.       */
/* Input   : The input data set and a variable(s) within it.                         */
/* Output  : ASCII output to the *.lst file (or the Output window) that includes     */
/*           the value of the Jarque Bera statistic and its p-value.                 */
/*                                                                                   */
/* Source  : http://www.sasanalysis.com/2010/03/macro-for-jarquebera-test.html       */
/*                                                                                   */
/* ********************************************************************************* */

%macro jarque_berra (data = , var = );
   ods listing close;
   proc univariate data = &data ;
       var &var;
      ods output moments = _1;
   run;
  
   data _2;
      set _1;
      label = label1; value = nValue1; output;
      label = label2; value = nValue2; output;
      drop cvalue: label1 label2 nvalue:;
   run;

   proc transpose data = _2 out = _3;
      by varname notsorted;
      id label;
      var value;
   run;

   data _4;
      set _3;
      jb = (skewness**2 * n)/6 + ((kurtosis)**2 *n)/24;
      p = 1 - probchi(jb, 2);
      lable jb = 'JB Statistic' p = 'P-value'
         kurtosis = 'Excess Kurtosis';
   run;
   ods listing;
   proc print data = _4 label;
      title "Jarque-Bera test for variable &var from data &data";
      var varname n skewness kurtosis jb p;
   run;

   proc datasets nolist;
      delete _:;
   quit;
%mend jarque_berra;

/* Run a test using a data set from SAS's HELP library */
/* %jbtest(data = sashelp.class, var = age height weight); */
