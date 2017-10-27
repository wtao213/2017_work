/**********************************/
/* import txt file to sas */
/*********************************/
FILENAME REFFILE 'C:/Users/sophia/Desktop/Output_Mom_LCL.txt';

PROC IMPORT DATAFILE=REFFILE
	DBMS=DLM
	OUT=WORK.lcl_mom;
	GETNAMES=YES;
	delimiter= '|'; /* specify special delimiter */
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=WORK.lcl_mom; RUN;

/* var Age SALES Unit Txn;
	class MBRSHIP_ID HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment MCH_0_CD 
		MCH_0_DESC_E;*/
		
/**************************************************/
/*				data frequency check				 */
/**************************************************/
proc freq data = lcl_mom order=freq;
	tables  MCH_0_CD MCH_0_DESC_E Unit Txn/ missing plots=freqplot;
run;

/************************************************/
/* checking customer number */
data mom_all;
	set lcl_mom;
run;

proc sort data= mom_all /*new is the file for no duplicate customer info*/
	/*dupout=mom_2013_du *//* all duplicate values are in mom 2009 file*/
	nodupkey;
	by MBRSHIP_ID;
run;

/*************************************************/
/** 			demographic info check			 */
/*************************************************/
proc freq data = mom_all order=freq;
	tables Age HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment  
		/ missing plots=freqplot;
run;

proc freq data = mom_all ;
	tables Age  SITE_NM CITY_NM GEND_CD Value_Segment 
		/ missing plots=freqplot;
run;

/*************************************************/
/* tabulate baby sales info */
/*****************************/
ods excel file='C:/Users/sophia/Desktop/mom_tables_lcl.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");

proc tabulate data=lcl_mom order=freq missing;
	class MBRSHIP_ID HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment MCH_0_CD 
		MCH_0_DESC_E;
	var Age SALES Unit Txn;
	
	/* tables SITE_NM , (SALES Unit)* ( sum colpctsum); */
	
	tables MCH_0_DESC_E all , (SALES Unit Txn)* (n sum colpctsum);
	
	tables GEND_CD all , (SALES Unit Txn)* (sum colpctsum);
	
	tables Value_Segment all , (SALES Unit Txn)* (sum colpctsum);
	
	tables GEND_CD*(MCH_0_DESC_E all) , (SALES Unit Txn)* (n sum colpctsum);
	
	tables Value_Segment*(MCH_0_DESC_E all) , (SALES Unit Txn)* (n sum colpctsum);
		
run;
ods excel close;


/**********************************/
/*	 import txt file to sas		 */
/*			version 2			*/
/*********************************/
FILENAME REFFILE 'C:/Users/sophia/Desktop/Output_Mom_Loblaw_ON_Part2.txt';

PROC IMPORT DATAFILE=REFFILE
	DBMS=DLM
	OUT=WORK.lcl_mom2;
	GETNAMES=YES;
	delimiter= '|'; /* specify special delimiter */
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=WORK.lcl_mom2; RUN;

/**************************************/
/*	lcl mom			**/
/*********************************/
data baby;
	set lcl_mom2;
	
	where MCH_1_DESC_E= "Baby";
	
run;

proc tabulate data= baby ;
	class MBRSHIP_ID HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment MCH_0_CD MCH_1_DESC_E
		MCH_0_DESC_E;
	var Age SALES Unit Txn;
	where index(SITE_NM,"Loblaw");
	tables GEND_CD all,sales * sum;
	
run;

/************************************************/
/* checking customer number */
data mom_all;
	set lcl_mom2;	
run;

data lcl_mom2;
	set lcl_mom2;
	
	format price_unit best8.;
	
	price_unit = sales/Unit ;	
run;


proc sort data= mom_all /*new is the file for no duplicate customer info*/
	/*dupout=mom_2013_du *//* all duplicate values are in mom 2009 file*/
	nodupkey;
	by MBRSHIP_ID;
run;

/*****************************************/
/* customer demographic info check */
/************************************/
proc freq data= mom_all order=freq;
	where index(SITE_NM,"Loblaw");
	tables Age SITE_NM CITY_NM GEND_CD Value_Segment/plots=freqplot missing;
run;

proc freq data= mom_all;
	where index(SITE_NM,"Loblaw");
	tables Age SITE_NM CITY_NM GEND_CD Value_Segment/plots=freqplot missing;
run;


/***************************************/
/* mom full data with total sales   */
/**************************************/

/*****************************************/
/*	var Age SALES Unit Txn;
	class MBRSHIP_ID HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment MCH_0_CD 
		MCH_0_DESC_E MCH_1_CD MCH_1_DESC_E; */
/********************************************/

proc summary data=lcl_mom2 nway missing; /* if no missing, we will loose all customer with incomplete demographic info */
	where index(SITE_NM,"Loblaw");
	class MBRSHIP_ID GEND_CD Value_Segment CITY_NM SITE_NM Age;
	var SALES Txn Unit price_unit;
	
	output out= sales_all(drop= _TYPE_ rename=(_freq_= MCH_num))  sum(SALES  Unit)= 
			idgroup(max(sales)out[5]( MCH_1_DESC_E sales Txn Unit price_unit )=top sales Txn Unit price_unit) ;
	/*remember MCH_num have MCH1 + 7 MCH0 in baby(MCH1) */
run;

proc export data= sales_all dbms=csv
	outfile='C:\Users\sophia\Desktop\mom_lcl_sales.csv' replace;
run;

/******************************************/
/* quick filter for outlier or fraud     */
/****************************************/
data small_business;
	set sales_all;
	
	where MCH_num <=10 and sales >2000;
	
	format price_unit best32.;
	
	price_unit = sales/Unit ;
		
run;

/*****************************************/
/* calculate baby sales by outliers  */
/*************************************/
proc sort data = small_business;
	by MBRSHIP_ID;
run;	

proc sort data= lcl_mom2;
	by MBRSHIP_ID;
run;

data merge_outlier;
 merge small_business(keep=MBRSHIP_ID in=a)	lcl_mom2 (in=b);
 by MBRSHIP_ID;
 if a and b;
run; 

proc tabulate data=merge_outlier missing order=freq;
 class MBRSHIP_ID HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment MCH_0_CD 
		MCH_0_DESC_E MCH_1_DESC_E;
	var Age SALES Unit Txn;
	
	tables MCH_1_DESC_E all, sales*(sum colpctsum);
run;

/********************************************/
/*	customer profile after deleting small business */
/*************************************************/
data lcl_mom_no_sb;
 merge small_business(keep=MBRSHIP_ID in=a)	lcl_mom2 (in=b);
 by MBRSHIP_ID;
 if a=0 and b=1;
run;  

	
proc export data= small_business dbms=csv
	outfile='C:\Users\sophia\Desktop\small_business.csv' replace;
run;
proc export data= merge_outlier dbms=csv
	outfile='C:\Users\sophia\Desktop\merge_outlier.csv' replace;
run;
/*******************************************/
/* all clients with primary store in loblaw */
/********************************************/
ods excel file='C:/Users/sophia/Desktop/mom_tables_lcl.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");

proc tabulate data=lcl_mom2 order=freq missing;

	where index(SITE_NM,"Loblaw") /*and MCH_1_DESC_E= "Baby" */;
	
	class MBRSHIP_ID HOME_SITE_NUM SITE_NM CITY_NM GEND_CD Value_Segment MCH_0_CD 
		MCH_0_DESC_E MCH_1_DESC_E;
	var Age SALES Unit Txn;
	
	/* tables SITE_NM , (SALES Unit)* ( sum colpctsum); */
	
	tables MCH_1_DESC_E all , (SALES Unit Txn)* (n sum colpctsum);
	
	tables MCH_0_DESC_E all , (SALES Unit Txn)* (n sum colpctsum);
	
	tables GEND_CD all , (SALES Unit Txn)* (sum colpctsum);
	
	tables Value_Segment all , (SALES Unit Txn)* (sum colpctsum);
	
	tables GEND_CD*(MCH_0_DESC_E all) , (SALES Unit Txn)* (n sum colpctsum);
	
	tables Value_Segment*(MCH_0_DESC_E all) , (SALES Unit Txn)* (n sum colpctsum);
	
	tables SITE_NM*(MCH_0_DESC_E all) , (SALES Unit Txn)* (n sum colpctsum);
		
run;
ods excel close;