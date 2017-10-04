/*************************************/
/* import mom data of VIB in 2013   */
/*************************************/

FILENAME REFFILE 'C:\Users\sophia\Desktop\VIB_2013_VIB_results.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.mom_2013;
	GETNAMES=YES;
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=mom_2013; RUN;

/******************************************/
/* reorginze the data for demographic info */
/* switch cashkey for some baby category */
/******************************************/
data mom_profile;
   set mom_2013;
	format sales dollar12.2;
	
	cat_descr = upcase(cat_descr);
	
	cashkey = upcase(cashkey);
	
	if cat_descr = "BABY ACCESSORIES"
					then cashkey_f = tranwrd(cashkey,'HEALTH BEAUTY AIDS EX BABY','HEALTH BEAUTY AIDS BABY ONLY');
	else if 	cat_descr =	"BABY TOILETRIES"
					then cashkey_f = tranwrd(cashkey,'HEALTH BEAUTY AIDS EX BABY','HEALTH BEAUTY AIDS BABY ONLY');
	else if 	cat_descr =	"DISPOSABLE DIAPERS"
					then cashkey_f = tranwrd(cashkey,'OTHER EX BABY','OTHER BABY ONLY');
	else if 	cat_descr =	"INFANT FEEDING"
					then cashkey_f = tranwrd(cashkey,'HEALTH BEAUTY AIDS EX BABY','HEALTH BEAUTY AIDS BABY ONLY');
	else if 	cat_descr =	"INFANT FORMULA"
					then cashkey_f = tranwrd(cashkey,'HEALTH BEAUTY AIDS EX BABY','HEALTH BEAUTY AIDS BABY ONLY');
	else				 cashkey_f = cashkey;
run;

data mom_2013;
	set mom_profile;
run;

proc sort data= mom_profile(drop= sales cashkey cat_descr promo_year  units txn gm) /*new is the file for no duplicate customer info*/
	dupout=mom_2013_du /* all duplicate values are in mom 2009 file*/
	nodupkey;
	by CUSTOMER_ID;
run;


/**********************************/
/* frequency tables of mom 2013 */
/*********************************/
proc freq data= mom_profile order=freq;
	tables age province_cd city tenure/ plots=freqplot;
run;

proc freq data= mom_profile ;
	tables age province_cd city tenure/ plots=freqplot;
run;

/********************************/
/* category sales by years */
/****************************/
ods excel file='C:/Users/sophia/Desktop/mom_tables_v2_13.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");

proc tabulate data=mom_2013 missing ;
	class promo_year city province_cd age cashkey cashkey_f tenure cat_descr;
	var sales units txn;
	
	/*format sales dollar12.2;*/
	
	tables promo_year, (sales units txn) *(sum colpctsum);
	
	tables age all,promo_year*(sales units txn) *(sum colpctsum);
	
	tables province_cd all,promo_year*(sales units txn) *(sum colpctsum);
	
	tables tenure all,promo_year*(sales units txn) *(sum colpctsum);
	
	tables cashkey all,promo_year*(sales units txn)*(sum colpctsum)
	/box='original cashkey';
	
	tables cashkey_f all,promo_year*(sales units txn)*(sum colpctsum)
	/box='revised cashkey';	

	tables cat_descr all,promo_year*(sales units txn)*(sum colpctsum);
		
run;
ods excel close;

/*******************************************************************/
/*aggregate original data set to customerid + year+ category      **/
/*******************************************************************/
proc summary data=mom_2013 nway;
	class promo_year cat_descr customer_id;
	var sales txn units ;
	
	output out=mom_by_cat sum(sales txn units)= 
	;
run;

********************************************/


/***************************************************************/
/* category sales  */
/**********************************/
ods excel file='C:/Users/sophia/Desktop/mom_tables_v2_sales_2013.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");

proc tabulate data=mom_by_cat missing ;
	class promo_year cat_descr customer_id;
	var sales txn units ;
	
	tables cat_descr all, promo_year*(sales txn units)*(n sum colpctsum);
	
run;
ods excel close;

/***************************************/
/* category sales dataset  */
/**********************************/
proc summary data=mom_by_cat(drop= _type_ _freq_ ) nway;
	class promo_year cat_descr ;
	var sales txn units ;
	
	output out= sales_by_category sum(sales txn units)= ;
run;

/* calculate mom engagement, sales/frequency/units per mom */
data sales_full;
	set sales_by_category;
	
	format mom_engage best12. txn_per_mom best12. units_per_mom best12. sales_per_unit best12.;
	
	mom_engage = _freq_ /4110; /* how many proportion mom buy this category*/
	
	txn_per_mom = txn / _freq_ ;
	
	units_per_mom = units / _freq_ ;
	
	sales_per_unit = sales / units;
run;

proc export data= sales_full dbms=csv
	outfile='C:\Users\sophia\Desktop\sales_info_2013.csv' replace;
run;