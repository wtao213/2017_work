



%macro wilson_transpose(n);


DATA TEMP&n.(rename=(category&n.=category category&n.sales=categorysales
					category&n.units=categoryunits category&n.txn=categorytxn));
	SET basket1(keep=mbrship_id timeframe salesbetween
						category&n. category&n.sales
					category&n.units category&n.txn);
run;

%mend wilson_transpose;

%wilson_tranpose(1); %wilson_tranpose(2); %wilson_tranpose(3);
%wilson_tranpose(4); %wilson_tranpose(5); %wilson_tranpose(6);
%wilson_tranpose(7); %wilson_tranpose(8); %wilson_tranpose(9);
%wilson_tranpose(10);

data final_data;
	set temp1-temp10;
run;

