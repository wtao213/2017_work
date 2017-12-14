/*************************************************/
/*	 import actual data set  			 */
/**********************************************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\Output_BestCustomer_revised.txt';

PROC IMPORT DATAFILE=REFFILE
	DBMS=dlm
	OUT=WORK.ac_behav;
	GETNAMES=YES;
	delimiter= "|";
	guessingrows= 5000;
RUN;

PROC CONTENTS DATA=ac_behav; RUN;

/*** convert membership to num */
data cs_total;
	set ac_behav;
	MembershipID = input(MBRSHIP_ID,best12.);
	drop MBRSHIP_ID;
run;

/**********************************************/
/*		 import master list 				  */
/**********************************************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\cus_full.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.customer_masterlist;
	GETNAMES=YES;
	guessingrows= 5000;
RUN;

PROC CONTENTS DATA=customer_masterlist; RUN;

/******************************************/
/*	 ds customer demographic info  */
/***********************************/
proc freq data= customer_masterlist ;
	where CUST_GRP_CD ="DS";
	tables  gender age_group pocket hRegion kizs_Q40 hhgroup Q39 Q2a Q42 Q43 Q44
	Q7r22Walmart Q7r23Costco Q7r12Metro Q7r6Sobeys Q7r32Food_Basics Q6_totalspend /missing plots=freqplot;
run;


proc sort data= customer_masterlist(drop= HOME_SITE_NUM Timeframe) out=process4 ;
	where CUST_GRP_CD ="DS";
	by MembershipID;
run;

proc sort data= cs_total;
	by MembershipID;
run;

data ds_full;
	merge process4(in=a) cs_total(drop= CUST_GRP_CD);
	by MembershipID;
	
	if a=1;
run;

/*******************************************/
/* get total sales for two years first  */
/*****************************************/
proc sort data=ds_full;
	by MembershipID Timeframe Category;
run;

proc summary data=ds_full missing nway;
	var MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn;
	class MembershipID Timeframe Category  hhgroup hRegion gender age_group pocket_index pocket;
	
	output out= ds_total_category(rename=(_freq_=txntypenum) drop= _TYPE_)  
	sum(MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn)= 
			/*idgroup(max(sales)out[3]( MCH_1_DESC_E sales Txn Unit )=top sales Txn Unit)*/ ;
run;

proc export data=ds_total_category dbms=xlsx outfile = "C:/Users/sophia/Desktop/ds_total_category.xlsx" replace;
run;

/************************************/
/* check transaction distribution */
/***********************************/
title "Q4  2016 - Q3 2017";
proc univariate data=WORK.DS_TOTAL_CATEGORY;
	
	where Category = "MFS" and Timeframe = "Q4  2016 - Q3 2017";
	var MKDStxn MKDSSales;
	histogram MKDStxn MKDSSales/ normal ;
run;

title "Q4  2015 - Q3 2016";
proc univariate data=WORK.DS_TOTAL_CATEGORY;
	
	where Category = "MFS" and Timeframe = "Q4  2015 - Q3 2016";
	var MKDStxn MKDSSales;
	histogram MKDStxn MKDSSales/ normal ;
run;

/**************************************/
/* high level summary for everyone  */
/*************************************/
proc tabulate data= ds_total_category;
	var MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn;
	class MembershipID Timeframe  Category hhgroup  pocket pocket_index;
	
	where Category= "MFS";
	
	tables hhgroup,(MKDSSales MKSALES DSSALES)*Timeframe*(n sum mean);
	
	tables hhgroup,(MKDStxn MKTxn DSTxn)*Timeframe*(n sum mean);
	
	tables hhgroup,(MKDSunits MKUnits DSUnits)*Timeframe*(n sum mean);
run;

proc tabulate data= ds_total_category;
	var MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn;
	class MembershipID Timeframe  Category hhgroup  pocket pocket_index;
	
	tables Category,(MKDSSales MKDStxn )*Timeframe*(n sum mean colpctsum);
run;


/********************************************/
/*   remove outlier for txn range 17-225  */
/*******************************************/
data dsprocess1;
	set ds_total_category;
	format  flag1 $8.;
	
	where Timeframe = "Q4  2016 - Q3 2017" and Category = "MFS";
	
	if 17 <=MKDStxn <=225 then flag1 = "keep";
	else					   flag1 = "remove"; /* flag the people we want to remove */
		
run;

data dsprocess2;
	set  ds_total_category;
	format  flag2 $8.;
	
	where Timeframe = "Q4  2015 - Q3 2016" and Category = "MFS";
	
	if 17 <=MKDStxn <=225 then flag2 = "keep";
	else					   flag2 = "remove";
run;

proc sort data=dsprocess1;
	by MembershipID;
run;

proc sort data=dsprocess2 (keep= MembershipID hhgroup flag2);
	by MembershipID;
run;

data ds_masterlist;
 merge dsprocess1 dsprocess2;
 by MembershipID;
 
 format flag $8.;
 if 		flag1 = "keep" and flag2 = "keep" then flag = "keep";
 else 											   flag = "remove"; 
run;

proc sort data=ds_masterlist(keep= MembershipID hhgroup hRegion gender age_group pocket_index pocket flag flag1 flag2);
	by MembershipID;
run; 

data ds_cus_everything;
	merge ds_masterlist(in=a) cs_total;
	by MembershipID;
	if a=1;
run;
	
/************************************************/
/* 		regroup customer's txn size  */
/*********************************************/
data txn_new;
	set ds_cus_everything;
	format triptype $12.;
	
	where hhgroup in ("family","couple");
	
	If 	    hhgroup = "family" and TxnBetween =  "0 and 19.99" then triptype = "Convenience";	
	else if hhgroup = "family" and TxnBetween = "20.00 and 39.99" then triptype = "Convenience";
	else if hhgroup = "family" and TxnBetween = "40.00 and 59.99" then triptype = "Fill";
	else if hhgroup = "family" and TxnBetween = "60.00 and 99.99" then triptype = "Fill";
	else if hhgroup = "family" and TxnBetween = "100.00 and 149.99" then triptype = "Full";
	else if hhgroup = "family" and TxnBetween = "150.00 and 199.99" then triptype = "Full";
	else if hhgroup = "family" and TxnBetween = "200.00 and 249.99" then triptype = "Full";
	else if hhgroup = "family" and TxnBetween = "250.00+" 			 then triptype = "Full";
	else if hhgroup = "couple" and TxnBetween =  "0 and 19.99" then triptype = "Convenience";
	else if hhgroup = "couple" and TxnBetween = "20.00 and 39.99" then triptype = "Convenience";
	else if hhgroup = "couple" and TxnBetween = "40.00 and 59.99" then triptype = "Fill";
	else if hhgroup = "couple" and TxnBetween = "60.00 and 99.99" then triptype = "Full";
	else if hhgroup = "couple" and TxnBetween = "100.00 and 149.99" then triptype = "Full";
	else if hhgroup = "couple" and TxnBetween = "150.00 and 199.99" then triptype = "Full";
	else if hhgroup = "couple" and TxnBetween = "200.00 and 249.99" then triptype = "Full";
	else 												 	          triptype = "Full";
run;
	
	
/******************************************/
/* regroup the basket size sales   */
/*************************************/
proc sort data =txn_new;
 BY MembershipID Timeframe triptype Category;
RUN;

proc summary data= txn_new missing nway;
	var MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn;
	class MembershipID Timeframe triptype Category hhgroup  flag pocket pocket_index hRegion gender age_group ;
	
	output out= txn_newtrip(rename=(_freq_=txntypenum))/*(drop= _TYPE_  _freq_)*/  
	sum(MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn)= 
			/*idgroup(max(sales)out[3]( MCH_1_DESC_E sales Txn Unit )=top sales Txn Unit)*/ ;
run;

proc export data=txn_newtrip dbms=xlsx outfile = "C:/Users/sophia/Desktop/ds_txn_newtrip.xlsx" replace;
run;

/***************************************************/
/* get summary info for txn_new  */
/***************************************/
ods excel file='C:/Users/sophia/Desktop/ds_txn_newtrip_table.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");

proc tabulate data=txn_newtrip missing;
	var MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn;
	class MembershipID Timeframe triptype Category hhgroup  flag pocket pocket_index;
	
	where flag="keep" and Category = "MFS";
	
	tables (hhgroup all)*triptype, (MKDSSales MKDSunits MKDStxn)*Timeframe*(n sum mean);
	
run;

proc tabulate data=txn_newtrip missing;
	var MKDSSales MKDSunits MKDStxn MKSALES MKUnits MKTxn DSSALES DSUnits DSTxn;
	class MembershipID Timeframe triptype Category hhgroup  flag pocket pocket_index;
	
	where flag="keep";
	
	tables hhgroup, Category, (MKDSSales MKDSunits MKDStxn)*triptype*Timeframe*(n sum colpctsum);
	
run;	
ods excel close;