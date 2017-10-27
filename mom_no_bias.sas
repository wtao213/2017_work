/********************************************/
/*		 mom with no bias 		  */
/********************************/
FILENAME REFFILE 'C:/Users/sophia/Desktop/Output_Mom_Loblaw_ON_Part2.txt';

PROC IMPORT DATAFILE=REFFILE
	DBMS=DLM
	OUT=WORK.lcl_mom2;
	GETNAMES=YES;
	delimiter= '|'; /* specify special delimiter */
	guessingrows= 500;
RUN;

PROC CONTENTS DATA=WORK.lcl_mom2; RUN;

proc summary data=lcl_mom2 nway missing; /* if no missing, we will loose all customer with incomplete demographic info */
	where index(SITE_NM,"Loblaw");
	class MBRSHIP_ID GEND_CD Value_Segment CITY_NM SITE_NM Age;
	var SALES Txn Unit price_unit;
	
	output out= sales_all(drop= _TYPE_ rename=(_freq_= MCH_num))  sum(SALES  Unit)= 
			idgroup(max(sales)out[5]( MCH_1_DESC_E sales Txn Unit price_unit )=top sales Txn Unit price_unit) ;
	/*remember MCH_num have MCH1 + 7 MCH0 in baby(MCH1) */
run;

data small_business;
	set sales_all;
	
	where MCH_num <=10 and sales >2000;
	
	format price_unit best32.;
	
	price_unit = sales/Unit ;
		
run;

proc sort data = small_business;
	by MBRSHIP_ID;
run;	

proc sort data= lcl_mom2;
	by MBRSHIP_ID;
run;

data lcl_mom_no_sb;
 merge small_business(keep=MBRSHIP_ID in=a)	lcl_mom2 (in=b);
 by MBRSHIP_ID;
 if a=0 and b=1;
run; 

ods excel file='C:/Users/sophia/Desktop/mom_tables_lcl_nobias.xlsx' style = pearl
options(sheet_interval = "table" sheet_name="none");
proc tabulate data=lcl_mom_no_sb order=freq missing;

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


/*************************************************/
/** 			demographic info check			 */
/*************************************************/
proc freq data = lcl_mom_no_sb order=freq;
	tables Age SITE_NM CITY_NM GEND_CD Value_Segment  Txn
		/ missing plots=freqplot;
run;

proc freq data = lcl_mom_no_sb ;
	tables Age  SITE_NM CITY_NM GEND_CD Value_Segment 
		/ missing plots=freqplot;
run;