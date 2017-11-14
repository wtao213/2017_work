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

/********************************/
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
	guessingrows= 2500;
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

/*******************************************/
/* muti table frequency check */
/************************************/
proc tabulate data=customer_final order=freq missing;
	var  FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc
	LCL_PURCHASER_TYPE_Q121	REGION2 USMAR2_Q73	HHCMP10_Q74	HH_KIDS_Q97
	SPENT_ON_GROCERY_Q111;
	
	where MCH_Desc = "Total";
	
	tables (Store_Divison all), (LCL_PURCHASER_TYPE_Q121 all) *n;
	
	tables (Store_Divison * HH_KIDS_Q97 all), (HHCMP10_Q74  all) *n;
run;

/***************************************/
/* combine household to groups  */
/**************************************/
proc format;
 value $fgroup
 
 	"1" = "single"
 	"2" = "couple"
 	"3" = "family"
 	"4" = "family"
 	other = "large family";	
 
 value spend
    . = "missing" /* always consider missing value  */
    200 - high = "$200 +"
    100-200 ="$100-$200"
    other = "<$200";
 
 value wallet
    . = "missing" 
    0   - 0.39 = "<40%"
    0.4 - 0.59 = "40%-59%"
    0.6 - 0.79 = "60%-79%" 
    0.8 - 0.89 = "80%-89%"
    0.9 - 0.99 = "90%-99%"
     other 	   = "100% +";   
run;


data customer_f1;
	set customer_final;
	format total_sales best8.	wk_tot_sales best8.	wk_ds_sales best8. tot_txn best8.
			wk_mk_sales  best8. high_bound_q111 best8. share_w best8.;
	
	hhgroup = put(HHCMP10_Q74,fgroup.);
	
	total_sales = sum(mk_sales,ds_sales);
	wk_mk_sales = mk_sales/52;
	wk_ds_sales = ds_sales/52;
	wk_tot_sales = total_sales /52;	
	tot_txn = sum(mk_txn,ds_txn);
	
	if 		SPENT_ON_GROCERY_Q111="Under $100" then high_bound_q111 = 100;
	else if SPENT_ON_GROCERY_Q111="$100-149" then high_bound_q111 = 125;
	else if SPENT_ON_GROCERY_Q111="$150-199" then high_bound_q111 = 175;
	else if SPENT_ON_GROCERY_Q111="$200-249" then high_bound_q111 = 225;
	else 									      high_bound_q111 = 250;
	
	share_w = wk_tot_sales/high_bound_q111; 
	/*share_w_group = put(share_w,wallet.);*/
	 if 			share_w= . 		then share_w_group = "missing"; 
  	else if  0  < share_w < 0.39	then share_w_group= "<40%";
  	else if  0.4 <share_w <0.59 then share_w_group = "40%-59%";
  	else if  0.6 <share_w <0.79 then share_w_group = "60%-79%" ;
  	else if  0.8 <share_w <0.89 then share_w_group = "80%-89%";
  	else if  0.9 <share_w < 0.99 then share_w_group = "90%-99%";
  	else    	 					  share_w_group = "100% +"; 
run;	



/***********************************************************/
/* how people say their spend, and how they acutally spend */
/************************************************************/
ods excel file='C:/Users/sophia/Desktop/share_of_wallet.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");
proc tabulate data = customer_f1 missing;
	var  FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc
	LCL_PURCHASER_TYPE_Q121	REGION2 USMAR2_Q73	HHCMP10_Q74	HH_KIDS_Q97
	SPENT_ON_GROCERY_Q111 hhgroup GROCERY_FREQUENCY PERCENTAGE_EXPENDITURE_LCL_Q112 
	INCOME_Q99 ETHNICITY_Q101 AREA_Q78 share_w_group;
	
	where Store_Divison="MK" and MCH_Desc = "Total";
	
	tables (hhgroup all) *(n );
	
	tables (hhgroup all),(share_w_group all)*(n rowpctn);
run;	
ods excel close;
		
proc export data=customer_f1 dbms=xlsx outfile = "C:/Users/sophia/Desktop/wallet_pen.xlsx" replace;
run;

/***************************************/
/* compare customer by household size  */
/*************************************/
ods excel file='C:/Users/sophia/Desktop/panel_result_hh_demo.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");
proc tabulate data=customer_f1 order=freq missing;
	var  FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc
	LCL_PURCHASER_TYPE_Q121	REGION2 USMAR2_Q73	HHCMP10_Q74	HH_KIDS_Q97
	SPENT_ON_GROCERY_Q111 hhgroup GROCERY_FREQUENCY PERCENTAGE_EXPENDITURE_LCL_Q112 
	INCOME_Q99 ETHNICITY_Q101 AREA_Q78;
	
	where MCH_Desc = "Total" and Store_Divison= "MK";
	
	tables Store_Divison , (hhgroup  all) *n;
	
	
	tables (hhgroup all),(Gender all)*(n rowpctn)/box="gender";
	
	tables (hhgroup all),(REGION2 all)*(n rowpctn)/box="region";
	
	tables (hhgroup all),(USMAR2_Q73 all)*(n rowpctn)/box="martarial";
	
	tables (hhgroup all),(HHCMP10_Q74 all)*(n rowpctn)/box="household size";
	
	tables (hhgroup all),(HH_KIDS_Q97 all)*(n rowpctn)/box="kids";
	
	tables (hhgroup all),(SPENT_ON_GROCERY_Q111 all)*(n rowpctn)/box="grocery spend";
	
	tables (hhgroup all),(age_range all)*(n rowpctn)/box="kids";
	
	tables (hhgroup all),(GROCERY_FREQUENCY all)*(n rowpctn)/box="kids";
	
	tables (hhgroup all),(PERCENTAGE_EXPENDITURE_LCL_Q112 all)*(n rowpctn)/box="kids";

	tables (hhgroup all),(INCOME_Q99 all)*(n rowpctn)/box="kids";
	
	tables (hhgroup all),(ETHNICITY_Q101 all)*(n rowpctn)/box="kids";
	
	tables (REGION2 all),(ETHNICITY_Q101 all)*(n rowpctn)/box="kids";
	
	tables (hhgroup all),(AREA_Q78 all)*(n rowpctn)/box="kids";

run;

ods excel close;

/**********************************/
/*	 frequency tables 			*/
/************************************/
proc freq data=customer_f1 order=freq;
	where MCH_Desc = "Total" and Store_Divison= "MK"; 
	tables RANGE  RESP_GENDER REGION1 REGION2 
		GROCERY_FREQUENCY G2_Q49 MOST_OFTEN_LCL_Q110 LCL_PURCHASER_TYPE_Q121 G2a_Q50 
		SPENT_ON_GROCERY_Q111 PERCENTAGE_EXPENDITURE_LCL_Q112
		USMAR2_Q73 HHCMP10_Q74 HH_KIDS_Q97 EMP01_Q98 USHHI2_Q75 INCOME_Q99 CAEDU2_Q76 
		CAETHN3_Q100 ETHNICITY_Q101 CANIM_Q77 USHOU1_Q102 AREA_Q78 LANG_Q114 EHV_Q120 
		SampleSegment_Q124 AgeRangeGrouped_Q125 RegionGrouped_Q126 
		HHIncome_Grouped_Q127 KIDS01_Q96_1
		 LC1_Q67_1 LC1_Q67_2 
		LC1_Q67_3 LC1_Q67_4 LC1_Q67_5 LC1_Q67_6 LC1_Q67_7 LC1_Q67_8 LC1_Q67_9 
		LC1_Q67_10 LC1_Q67_11 LC1_Q67_12 LC1_Q67_13 LC1_Q67_14 LC1_Q67_15 On1_Q68_1 
		 BIRTH_MONTH BIRTH_YEAR Age/plots=freqplot missing;
run;

/*************************************************/
/* check competitiors for couple and family groups  */
/***********************************/
proc freq data=customer_f1 order=freq;
	where MCH_Desc = "Total" and Store_Divison= "MK" and hhgroup in ("couple","family"); 
	tables	G1_Q48_1 G1_Q48_2 G1_Q48_3 G1_Q48_4 G1_Q48_5 G1_Q48_6 
		G1_Q48_7 G1_Q48_8 G1_Q48_9 G1_Q48_10 G1_Q48_11 G1_Q48_12 G1_Q48_13 G1_Q48_14 
		G1_Q48_15 G1_Q48_16 G1_Q48_17 G1_Q48_18 G1_Q48_19 G1_Q48_20 G1_Q48_21 
		G1_Q48_22 G1_Q48_23 G1_Q48_24 G1_Q48_25 G1_Q48_26 G1_Q48_27 G1_Q48_28 
		G1_Q48_29 G1_Q48_30 G1_Q48_31 G1_Q48_32 G1_Q48_33 G1_Q48_34 G1_Q48_35 
		G1_Q48_36 G1_Q48_37 G1_Q48_38 G1_Q48_39 G1_Q48_40/plots=freqplot missing;
run;
/***********************************************************/
/* how people say their spend, and how they acutally spend */
/************************************************************/
/* full wallet for family set as $220, couple set as $114  */
/************************************************************/
data fc_v1;
	set customer_f1;
	format pocket $12.;
	where hhgroup in ("couple","family") and Store_Divison= "MK" and MCH_Desc = "Total";
	
	if		hhgroup = "family" and wk_tot_sales > 200 	then pocket = "full";
	else if hhgroup = "family" and wk_tot_sales >176 	then pocket = "80%+";
	else if hhgroup = "family" and wk_tot_sales >132 	then pocket = "60%-80%";
	else if hhgroup = "family" 						 	then pocket = "<60%";
	else if hhgroup = "couple" and wk_tot_sales >100 	then pocket = "full";
	else if hhgroup = "couple" and wk_tot_sales >91 	then pocket = "80%+";
	else if hhgroup = "couple" and wk_tot_sales >68.4	then pocket = "60%-80%";
	else 					 						 	     pocket = "<60%";
	
run;
/**********************************************************/
/* cut off the highest 5% and lowest 5% tot_txn customers */
/***********************************************************/
proc sort data=fc_v1 out=fc_v1_nooutlier;
		by tot_txn;
run;

proc summary data=fc_v1_nooutlier;
	var tot_txn;
	output out=test1 p5= p95= /autoname;
run;

data _null_;
	set test1;
	call symputx('p5',tot_txn_p5);
	call symputx('p95',tot_txn_p95);
run;
%put &p5;
%put &p95;

data fc_v2;
	set fc_v1_nooutlier;
	
	where &p5 le tot_txn le &p95;
run;


/***********************************************************/
/* merge the idea customer set   */
/*********************************/
proc sort data=fc_v2(keep=pocket MembershipID tot_txn);
	by MembershipID;
run;

proc sort data=customer_f1;
	by MembershipID;
run;

data fc_full;
	merge customer_f1(in=a) fc_v1(in=b);
	by MembershipID;
	
	if b=1;
run;

/*****************************************/
/* tabulate the results */
/*************************/
ods excel file='C:/Users/sophia/Desktop/pocket_category.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");
proc tabulate data=fc_full missing;
	var  FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn total_sales
	wk_mk_sales wk_tot_sales wk_ds_sales tot_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc
	LCL_PURCHASER_TYPE_Q121	REGION2 USMAR2_Q73	HHCMP10_Q74	HH_KIDS_Q97
	SPENT_ON_GROCERY_Q111 hhgroup GROCERY_FREQUENCY PERCENTAGE_EXPENDITURE_LCL_Q112 
	INCOME_Q99 ETHNICITY_Q101 AREA_Q78 pocket MCH_Desc;
	
	where MCH_Desc= "Total";
	
	tables pocket all, (hhgroup all)*(n colpctn);
	
	tables (hhgroup all),(pocket all)*(wk_mk_sales)*(n mean);
	
	tables (hhgroup all),(pocket all)*(wk_ds_sales)*(n mean);
	
	tables (hhgroup all),(pocket all)*(wk_tot_sales)*(n mean);
	
	tables (hhgroup all),(pocket all)*(mk_txn)*(n mean);
	
	tables (hhgroup all),(pocket all)*(ds_txn)*(n mean);
	
	tables (hhgroup all),(pocket all)*(tot_txn)*(n mean);
run;

proc tabulate data=fc_full missing;
	var  FICO_STORE ds_sales ds_units ds_txn mk_sales mk_units mk_txn total_sales
	wk_mk_sales wk_tot_sales wk_ds_sales tot_txn;
	class time_frame Store_Divison Value_Segment age_range Gender MCH_Desc
	LCL_PURCHASER_TYPE_Q121	REGION2 USMAR2_Q73	HHCMP10_Q74	HH_KIDS_Q97
	SPENT_ON_GROCERY_Q111 hhgroup GROCERY_FREQUENCY PERCENTAGE_EXPENDITURE_LCL_Q112 
	INCOME_Q99 ETHNICITY_Q101 AREA_Q78 pocket MCH_Desc ;
	
	where MCH_Desc ~= "Total";
	
	tables MCH_Desc,(hhgroup all)*(pocket all)*(wk_tot_sales)*(n sum colpctsum);
	
	tables MCH_Desc,(hhgroup all)*(pocket all)*(wk_mk_sales)*(n sum colpctsum);
	
	tables MCH_Desc,(hhgroup all)*(pocket all)*(wk_ds_sales)*(n sum colpctsum);
	
	tables MCH_Desc,(hhgroup all)*(pocket all)*(mk_txn)*(n sum colpctsum);
	
	tables MCH_Desc,(hhgroup all)*(pocket all)*(ds_txn)*(n sum colpctsum);
	
	tables MCH_Desc,(hhgroup all)*(pocket all)*(tot_txn)*(n sum colpctsum);
run;
ods excel close;

proc export data=fc_full dbms=xlsx outfile = "C:/Users/sophia/Desktop/fc_full.xlsx" replace;
run;

/***********************************/
/* plots for txn  */
/************************/
ods noproctitle;
ods graphics / imagemap=on;

/*** Exploring Data ***/
proc univariate data=WORK.FC_FULL;
	
	where MCH_Desc= "Total";
	var tot_txn;
	histogram tot_txn/normal;
run;

title "couple only";
proc univariate data=WORK.FC_FULL;
	
	where hhgroup="couple" and  MCH_Desc= "Total";
	var tot_txn;
	histogram tot_txn/normal;
run;


title "family only";
proc univariate data=WORK.FC_FULL;
	
	where hhgroup="family" and MCH_Desc= "Total";
	var tot_txn;
	histogram tot_txn/normal;
run;