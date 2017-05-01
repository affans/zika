clc;
clear;
aSummer=0.0018;
bSummer=0.3228;
sSummer=2.1460;

aWinter=0.0018;
bWinter=0.8496;
sWinter=4.2920;

for t=1:60+1
    timeS(t)=t;
%    HS(t)= aSummer*exp(bSummer*(t-1))./(1+aSummer*sSummer*(exp(bSummer*(t-1))-1)./bSummer);
    HS=@(t)aSummer*exp(bSummer*(t-1))./(1+aSummer*sSummer*(exp(bSummer*(t-1))-1)./bSummer);
    KS(t)=integral(HS,0,t);
%    KS(t)=sum(HS(1:t));
    SurS(t)=exp(-KS(t));
    PDFS(t)=HS(t).*SurS(t);
end

for tt=1:35+1
    timeW(tt)=tt;
%    HW(tt)= aWinter*exp(bWinter*(tt-1))./(1+aWinter*sWinter*(exp(bWinter*(tt-1))-1)./bWinter);
    HW=@(tt)aWinter*exp(bWinter*(tt-1))./(1+aWinter*sWinter*(exp(bWinter*(tt-1))-1)./bWinter);
    KW(tt)=integral(HW,0,tt);
%    KW(tt)=sum(HW(1:tt));
    SurW(tt)=exp(-KW(tt));
    PDFW(tt)=HW(tt).*SurW(tt);
end

plot(cumsum(PDFS))
figure
plot(cumsum(PDFW))
