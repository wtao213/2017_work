/************************************/
/*   input the survey demographic data	*/
/***********************************/
FILENAME REFFILE 'C:\Users\sophia\Desktop\survey_answer_demo.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.survey;
	GETNAMES=YES;
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=survey; RUN;

/***************************************/
/* 	demographic info of them    */
/**********************************/
/*	var MembershipID BIRTH_YEAR Age G3_Q51_1 SUM_PERCENTAGE_EXPENDITURE_LCL_Q 
		KIDS01_Q96_1;
	class BIRTH_MONTH RANGE AGE_TERM RESP_GENDER REGION1 REGION2 Q87 
		GROCERY_FREQUENCY G2_Q49 MOST_OFTEN_LCL_Q110 LCL_PURCHASER_TYPE_Q121 G2a_Q50 
		SPENT_ON_GROCERY_Q111 PERCENTAGE_EXPENDITURE_LCL_Q112 LC1_Q67_1 LC1_Q67_2 
		LC1_Q67_3 LC1_Q67_4 LC1_Q67_5 LC1_Q67_6 LC1_Q67_7 LC1_Q67_8 LC1_Q67_9 
		LC1_Q67_10 LC1_Q67_11 LC1_Q67_12 LC1_Q67_13 LC1_Q67_14 LC1_Q67_15 On1_Q68_1 
		USMAR2_Q73 HHCMP10_Q74 HH_KIDS_Q97 EMP01_Q98 USHHI2_Q75 INCOME_Q99 CAEDU2_Q76 
		CAETHN3_Q100 ETHNICITY_Q101 CANIM_Q77 USHOU1_Q102 AREA_Q78 LANG_Q114 EHV_Q120 
		SampleSegment_Q124 AgeRangeGrouped_Q125 RegionGrouped_Q126 
		HHIncome_Grouped_Q127;*/
		
/**********************************/
/*	 frequency tables 			*/
/************************************/
proc freq data=survey order=freq;
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


proc univariate data=WORK.SURVEY vardef=df noprint ;	
	var  BIRTH_YEAR Age G3_Q51_1 SUM_PERCENTAGE_EXPENDITURE_LCL_Q 
		KIDS01_Q96_1;
	histogram  BIRTH_YEAR Age G3_Q51_1 
		SUM_PERCENTAGE_EXPENDITURE_LCL_Q KIDS01_Q96_1;
run;

/************************************************/
/* import all the question answers  */
/************************************/

FILENAME REFFILE 'C:\Users\sophia\Desktop\survey_result.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.survey;
	GETNAMES=YES;
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=survey; RUN;


/******************************
	var	 'MembershipID _Q123_1'n 'KIDS01 _Q96_1'n 'G3 _Q51_1'n 
		'SUM_PERCENTAGE_EXPENDITURE_LCL _'n;
	class 'USMAR2 _Q73'n 'HHCMP10 _Q74'n 'USHHI2 _Q75'n 'CAETHN3 _Q100'n 
		'G2 _Q49'n 'G2a _Q50'n 'SPENT_ON_GROCERY _Q111'n 
		'PERCENTAGE_EXPENDITURE_LCL _Q112'n 'G5 _Q108_A_1'n 'G5 _Q108_A_2'n 
		'G5 _Q108_A_3'n 'G5 _Q108_A_4'n 'G5 _Q108_A_5'n 'G5 _Q108_A_6'n 
		'G5 _Q108_A_7'n 'G5 _Q108_A_8'n 'G5 _Q108_A_9'n 'G6 _Q109_A_1'n 
		'G6 _Q109_A_2'n 'G6 _Q109_A_3'n 'G6 _Q109_A_4'n 'G6 _Q109_A_5'n 
		'G6 _Q109_A_6'n 'G7 _Q56'n 'SC1 _Q63_A_1'n 'SC1 _Q63_A_2'n 'SC1 _Q63_A_3'n 
		'SC1 _Q63_A_4'n 'SC1 _Q63_A_5'n 'SC1 _Q63_A_6'n 'SC1 _Q63_A_7'n 
		'SC1 _Q63_A_8'n 'SC1 _Q63_A_9'n 'SC1 _Q63_A_10'n 'SC1 _Q63_A_11'n 
		'SC1 _Q63_A_12'n 'SC1 _Q63_A_13'n 'SC1 _Q63_A_14'n 'SC1 _Q63_A_15'n 
		'SC1 _Q63_A_16'n 'SC1 _Q63_A_17'n 'SC2 _Q116_A_1'n 'SC2 _Q116_A_2'n 
		'SC2 _Q116_A_3'n 'SC2 _Q116_A_4'n 'SC2 _Q116_A_5'n 'SC2 _Q116_A_6'n 
		'SC2 _Q116_A_7'n 'SC2 _Q116_A_8'n 'SC2 _Q116_A_9'n 'SC2 _Q116_A_10'n 
		'SC2 _Q116_A_11'n 'SC2 _Q116_A_12'n 'SC2 _Q116_A_13'n 'SC2 _Q116_A_14'n 
		'SC2 _Q116_A_15'n 'SC2 _Q116_A_16'n 'SC2 _Q116_A_17'n 'SC3 _Q107_A_1'n 
		'SC3 _Q107_A_2'n 'SC3 _Q107_A_3'n 'SC3 _Q107_A_4'n 'SC3 _Q107_A_5'n 
		'SC3 _Q107_A_6'n 'SC3 _Q107_A_7'n 'SC3 _Q107_A_8'n 'SC3 _Q107_A_9'n 
		'SC3 _Q107_A_10'n 'SC3 _Q107_A_11'n;
		******************************/
/***************************************/
/* using pca to reduce dimensions    */
/************************************/
proc factor data= survey out= pca_r outstat=pca_data plots=all m=ml rotate=varimax;
	var ;
run;