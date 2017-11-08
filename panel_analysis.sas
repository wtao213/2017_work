/*************************************************/
/* import data set only have time frame A  */
/**********************************************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\cus_info_ta.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.ac_behav;
	GETNAMES=YES;
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=ac_behav; RUN;

/****************************************/
/* var MBRSHIP_ID FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc;
*/

/******************************/
/* check division by home store */
/*******************************/
proc freq data=ac_behav order=freq;
	where MCH_Desc = "Total";
	tables Store_Divison/plots=freqplot missing;	
run;


/*******************************/
/* import survey data  */
/***********************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\survey_answer_demo.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.survey;
	GETNAMES=YES;
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=survey; RUN;

proc sort data=survey out=survey2;
	by	MembershipID;
run;

proc sort data=ac_behav(rename=(MBRSHIP_ID=MembershipID));
	by	MembershipID;
run;

/****************************************/
/* get eventually merge data set only customer */
/***********************************/
data customer_final;
	merge ac_behav(in=a) survey2(in=b);
	by MembershipID;
	
	if a=1;
run;

data customer_demographic;
	set customer_final;
	where MCH_Desc = "Total";
run;

/***************************************/
/* compare customer by division   */
/***********************************/
ods excel file='C:/Users/sophia/Desktop/panel_result.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");

proc tabulate data=customer_final order=freq;
	var  FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc
	LCL_PURCHASER_TYPE_Q121	REGION2 USMAR2_Q73	HHCMP10_Q74	HH_KIDS_Q97
	SPENT_ON_GROCERY_Q111;
	
	where MCH_Desc = "Total";
	
	tables (Store_Divison all)*(LCL_PURCHASER_TYPE_Q121 all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum )/box="division verify";
	
	tables (Store_Divison all)*(Gender all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum)/box="gender";
	
	tables (Store_Divison all)*(REGION2 all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum)/box="region";
	
	tables (Store_Divison all)*(USMAR2_Q73 all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum)/box="martarial";
	
	tables (Store_Divison all)*(HHCMP10_Q74 all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum)/box="household size";
	
	tables (Store_Divison all)*(HH_KIDS_Q97 all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum)/box="kids";
	
	tables (Store_Divison all)*(SPENT_ON_GROCERY_Q111 all),
	(ds_sales ds_units ds_txn mk_sales mk_units mk_txn )*(n sum)/box="grocery spend";
run;
ods excel close;