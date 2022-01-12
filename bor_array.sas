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

data cr; set out3;
array avalc [*] avalc: ;
array adt [*] adt: ; 
do k1=1 to dim(avalc)-1;
if avalc[k1]='CR' and avalc[k1+1]='CR' and adt[k1+1]-adt[k1]>=28 then do;
adt_cr=adt[k1]; output;
end;
end;
do k2=1 to dim(avalc)-2;
if avalc[k2]='CR' and avalc[k2+1]='NE' and avalc[k2+2]='CR' and adt[k2+2]-adt[k2]>=28 then do; 
adt_cr=adt[k2]; output;
end;
end; 
run;

data pr; set out3; 
array avalc [*] avalc: ;
array adt [*] adt: ; 
do k3=1 to dim(avalc)-1;
if avalc[k3]='PR' and avalc[k3+1] in ('PR','CR') and adt[k3+1]-adt[k3]>=28 then do;
adt_pr=adt[k3]; output;
end;
end; 
do k4=1 to dim(avalc)-2; 
if avalc[k4]='PR' and avalc[k4+1] in ('SD','NE') and avalc[k4+2] in ('PR','CR') and adt[k4+2]-adt[k4]>=28 then do;
adt_pr=adt[k4]; output;
end;
end;
run;

data sd; set out3; 
array avalc [*] avalc: ;
array adt [*] adt: ; 
do k5=1 to dim(avalc);
if avalc[k5] in ('SD','PR','CR') and adt[k5]-trtsdt>=35 then do;
adt_sd=adt[k5]; output;
end;
end; 
run;


data pd; set out3; 
array avalc [*] avalc: ;
array adt [*] adt: ; 
do k6=1 to dim(avalc);
if avalc[k6]='PD' then do;
adt_pd=adt[k6]; output;
end; 
end;
run;

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

proc print data=final;
run;




















