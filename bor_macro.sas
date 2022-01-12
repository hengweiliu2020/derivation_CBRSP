libname adam "C:\PHUSE\temp";

data tr(keep=usubjid adt_tum); set adam.adtr;
where parqual='CENTRAL' and tracptfl='Y' and .z<trtsdt<adt; 
adt_tum=adt; 

proc sort data=tr; by usubjid adt_tum;
data tr; set tr;
by usubjid adt_tum;
if first.usubjid;
run;

proc sort data=adam.adrs out=aa(keep=usubjid avalc adt visit); by usubjid adt;
where paramcd='OVRLRESP' and parqual='CENTRAL' and rsacptfl='Y' and (adt<=min(fpddt, nwtrsdt) or min(fpddt, nwtrsdt)<.z);

proc transpose data=aa out=out1 prefix=avalc; 
var avalc;
by usubjid; 

proc transpose data=aa out=out2 prefix=adt; 
var adt;
by usubjid; 
run;

data out3; 
merge out1(in=a) out2 adam.adsl(keep=usubjid trtsdt); 
by usubjid;
if a;
run;

%macro bor; 

proc sql;
create table a1 as 
select count(distinct adt) as ct from aa group by usubjid;
select max(ct) into:tot from a1; 

data cr; set out3;
%do k=1 %to %eval(&tot-1);
if avalc&k='CR' and avalc%eval(&k+1)='CR' and adt%eval(&k+1)-adt&k>=28 then do; 
adt_cr=adt&k; output;
end;
%end;
%do k=1 %to %eval(&tot-2);
if avalc&k='CR' and avalc%eval(&k+1)='NE' and avalc%eval(&k+2)='CR' and adt%eval(&k+2)-adt&k>=28 then do; 
adt_cr=adt&k; output;
end;
%end;
run;

data pr; set out3; 
%do k=1 %to %eval(&tot-1);
if avalc&k='PR' and avalc%eval(&k+1) in ('PR','CR') and adt%eval(&k+1)-adt&k>=28 then do; 
adt_pr=adt&k; output;
end;
%end;

%do k=1 %to %eval(&tot-2);
if avalc&k='PR' and avalc%eval(&k+1) in ('SD','NE') and avalc%eval(&k+2) in ('PR','CR') and adt%eval(&k+2)-adt&k>=28 then do; 
adt_pr=adt&k; output;
end;
%end;
run;

data sd; set out3; 
%do k=1 %to &tot;
if avalc&k in ('SD','PR','CR') and adt&k-trtsdt>=35 then do;
adt_sd=adt&k; output;
end; 
%end;

data pd; set out3; 
%do k=1 %to &tot; 
if avalc&k='PD' then do;  
adt_pd=adt&k; output; 
end;
%end;

proc sort data=cr; by usubjid adt_cr;
proc sort data=pr; by usubjid adt_pr;
proc sort data=sd; by usubjid adt_sd; 

data cr; set cr;
by usubjid adt_cr;
if first.usubjid;
run;

data pr; set pr; 
by usubjid adt_pr;
if first.usubjid;

data sd; set sd;
by usubjid adt_sd;
if first.usubjid;
run;

data final(keep=usubjid avalc adt paramcd param);
merge out3(in=m) cr(in=a) pr(in=b) sd(in=c) pd(in=d) tr;
by usubjid;
if m;
if a then do; avalc='CR'; adt=adt_cr; end;
else if b then do; avalc='PR'; adt=adt_pr; end;
else if c then do; avalc='SD'; adt=adt_sd; end;
else if d then do; avalc='PD'; adt=adt_pd; end;
else do; avalc='NE'; adt=adt_tum; end; 
paramcd='CBRSP';
param='Confirmed Best Overall Response'; 
format adt yymmdd10.;
run;

%mend;

%bor;


proc print data=final;
run;





















