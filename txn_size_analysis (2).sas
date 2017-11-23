/*****************************/
/* import panel basket full */
/*****************************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\panel_basket_full.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.panel_basket_full;
	GETNAMES=YES;
	guessingrows= 1500;
RUN;

PROC CONTENTS DATA=panel_basket_full; RUN;

/*****************************/
/* regroup the basket size  */
/****************************/
proc format;
value $txngroup
	'0 and 9.99','10.00 and 19.99'  ='$0-19.99'
	'20.00 and 29.99','30.00 and 39.99'='$20-39.99'
	'40.00 and 49.99','50.00 and 59.99'='$40-59.99'
	'60.00 and 69.99','70.00 and 79.99','80.00 and 89.99','90.00 and 99.99' ='$60-99.99'
	'100.00 and 149.99'='$100-149.99'
	'150.00 and 199.00'='$150-199.99'
	'200.00 and 249.99'='$200-249.99'
	'250.00+'='$250+'
	;
run;

data basket1;
	set panel_basket_full;
	format txngroupnew $64.;
	
	txngroupnew = put(salesBetween,$txngroup.);
run;

/***********************************/
/* set subject to original dataset */
/***********************************/
data prepare;
	set basket1;
	
	subject +1;
run;

proc transpose data=prepare out=longcat prefix=cat;
	by subject;	
	var Category1 Category2 Category3 Category4 Category5 
		Category6 Category7 Category8 Category9 Category10;
run;

proc transpose data=prepare out=longsales prefix=sales;
	by subject;	
	var Category1Sales Category2Sales Category3Sales Category4Sales Category5Sales 
		Category6Sales Category7Sales Category8Sales Category9Sales Category10Sales;
run;

proc transpose data=prepare out=longtxn prefix=txn;
	by subject;	
	var Category1Txn Category2Txn Category3Txn Category4Txn Category5Txn 
		Category6Txn Category7Txn Category8Txn Category9Txn Category10Txn;
run;

proc transpose data=prepare out=longunit prefix=Units;
	by subject;	
	var Category1Units Category2Units Category3Units Category4Units Category5Units 
		Category6Units Category7Units Category8Units Category9Units Category10Units;
run;

/******************************************/
/* combine the info together  */
/********************************/
data long;
	merge longcat(drop=_name_) longsales(drop=_name_) longtxn(drop=_name_) longunit(drop=_name_);
	by subject;
run;

proc sort data=prepare(keep=subject  Timeframe salesBetween MembershipID  
						sales units Txn Range pocket  hhgroup txngroupnew) out=prepare2;
	by subject;
run;

data basket_full_raw;
	merge long prepare2;
	by subject;
run;

proc export data=basket_full_raw dbms=xlsx outfile = "C:/Users/sophia/Desktop/basket_full_raw.xlsx" replace;
run;
/*****************************/
/* import panel basket full */
/*****************************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\basket_full_raw.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.basket_full_raw;
	GETNAMES=YES;
	guessingrows= 1500;
RUN;

PROC CONTENTS DATA=basket_full_raw; RUN;


/***************************************/
/* combine the size basket together */
/***************************************/
proc sort data=basket_full_raw;
	by MembershipID Timeframe txngroupnew cat1;
run;

proc summary data=basket_full_raw missing nway;
	var sales1 txn1 Units1;
	class MembershipID Timeframe txngroupnew cat1 hhgroup pocket;
	
	output out= basket_full_newgroup(drop= _TYPE_  _freq_)  sum(sales1 txn1 Units1)= 
			/*idgroup(max(sales)out[3]( MCH_1_DESC_E sales Txn Unit )=top sales Txn Unit)*/ ;
run;

proc export data=basket_full_newgroup dbms=xlsx outfile = "C:/Users/sophia/Desktop/basket_full_newgroup.xlsx" replace;
run;
/***************************************/
/* get summary table for the new group */
/***************************************/
ods excel file='C:/Users/sophia/Desktop/basket_full_newgroup.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");
proc tabulate data=basket_full_newgroup missing ;
	var MembershipID sales1 txn1 Units1;
	class Timeframe txngroupnew cat1 hhgroup pocket;
	
	tables cat1 all, Timeframe*(hhgroup all)*(sales1 txn1 Units1)*(sum colpctsum) ;
	
	tables Timeframe,cat1 all, hhgroup*pocket*(sales1 txn1 Units1)*(sum colpctsum) ;
	
	/*tables cat1 all, Timeframe*hhgroup*pocket*txngroupnew*(sales1 txn1 Units1)*(sum colpctsum) ;*/
	
	/*tables cat1 all, Timeframe*hhgroup*txngroupnew*(sales1 txn1 Units1)*(n sum colpctn) ;*/
run;
ods excel close;

/****************************/
/* shows the top 5 by txn  */
/***************************/
proc summary data=basket_full_raw missing nway;
	var sales1 txn1 Units1;
	class MembershipID Timeframe txngroupnew hhgroup pocket;
	
	output out= basket_top5_txn(drop= _TYPE_  _freq_)  sum(sales1  Units1)=top10sales top10units 
			idgroup(max(txn1)out[5]( cat1 sales1 txn1 Units1 )=top sales Txn Unit) ;
run;

proc export data=basket_top5_txn dbms=xlsx outfile = "C:/Users/sophia/Desktop/basket_top5_txn.xlsx" replace;
run;

/***************************************/
/* get summary table for the new group */
/***************************************/

/********************************************/
/* top 5 txn category  */
/*****************************/
proc tabulate data=basket_top5_txn missing ;
	var MembershipID top10sales top10units sales_1 sales_2 sales_3 sales_4 sales_5 
		Txn_1 Txn_2 Txn_3 Txn_4 Txn_5 Unit_1 Unit_2 Unit_3 Unit_4 Unit_5;
	class Timeframe txngroupnew hhgroup pocket top_1 top_2 top_3 top_4 top_5;

	
	tables top_1 all, Timeframe*hhgroup*txngroupnew*(n colpctn);
run;