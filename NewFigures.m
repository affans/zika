clear; clc;
load 'latent.dat'
% load 'SymptomaticIncidence.dat'
% load 'AsymptomaticIncidence.dat'
% load 'SexualTransmissionFromAsymp.dat'
% load 'SexualTransmissionFromSymp.dat'

% % % % % % % R0=2.2;
% % % % % % % S0=100000;
% % % % % % % %% calculating R effective at the end of wave 1
% % % % % % % % ignoring the sims with no real epidemic in the first wave
% % % % % % % h1=0;
% % % % % % % for i=1:500
% % % % % % %     K1=sum(SymptomaticIncidence(i,1:60))*S0;%+ ...
% % % % % % % %        sum(AsymptomaticIncidence(i,60:364))*S0;
% % % % % % %     if (K1>=R0*5)
% % % % % % %         idx1(i)=i;
% % % % % % %         h1=h1+1;
% % % % % % %     else
% % % % % % %         idx1(i)=0;
% % % % % % %     end
% % % % % % % end
% % % % % % % Wave1=find(idx1>0);
% % % % % % % 
% % % % % % % % attack rate and Reff1 for wave 1 
% % % % % % % for i=1:length(Wave1)
% % % % % % %     infection1(i)=sum(SymptomaticIncidence(Wave1(i),1:364))*S0+ ...
% % % % % % %         sum(AsymptomaticIncidence(Wave1(i),1:364))*S0;
% % % % % % %     inf1=infection1(i);
% % % % % % %     Reff1(i)=((S0-inf1)/S0)*R0;
% % % % % % % end
% % % % % % % OverallAttackRate=mean(infection1/S0)
% % % % % % % mReff1=mean(Reff1)
% % % % % % % % 95% confidence interval for Reff1
% % % % % % % SEM = std(Reff1(1,:))/sqrt(length(Reff1(1,:)));
% % % % % % % ts = tinv([0.025  0.975],length(Reff1(1,:))-1);
% % % % % % % CI = mean(Reff1(1,:)) + ts*SEM
% % % % % % % 
% % % % % % % 
% % % % % % % % find simulations that did not die out for the second wave
% % % % % % % h2=0;
% % % % % % % for i=1:500
% % % % % % %       K2=sum(SymptomaticIncidence(i,365+60:731))*S0;%+ ...
% % % % % % % %          sum(AsymptomaticIncidence(i,365+60:731))*S0;
% % % % % % %       KK2=sum(SymptomaticIncidence(i,364:365+7))*S0;%+ ...
% % % % % % % %          sum(AsymptomaticIncidence(i,364:365+7))*S0;
% % % % % % %     if (K2>=mReff1*KK2)
% % % % % % %         idx2(i)=i;
% % % % % % %         h2=h2+1;
% % % % % % %     else
% % % % % % %         idx2(i)=0;
% % % % % % %       end
% % % % % % % end
% % % % % % % Wave2=find(idx2>0);
% % % % % % % 
% % % % % % % % finding the probability of second wave occurring
% % % % % % % ProbWave2=length(Wave2)/length(Wave1)
% % % % % % % 
% % % % % % % %% sexual transmission
% % % % % % % for i=1:length(Wave1)
% % % % % % %     Sympsex(i)=sum(SexualTransmissionFromSymp(Wave1(i),1:364));
% % % % % % %     Asympsex(i)=sum(SexualTransmissionFromAsymp(Wave1(i),1:364));
% % % % % % %     Ssex=Sympsex(i);
% % % % % % %     Asex=Asympsex(i);
% % % % % % %     Totalsex(i)=Ssex+Asex;
% % % % % % % end
% % % % % % % MTotalSex=mean(Totalsex)
% % % % % % % Sexratio=MTotalSex/(OverallAttackRate*S0)
% % % % % % % 
% % % % % % % % percentage of Reffective due to sex
% % % % % % % for i=1:length(Wave1)
% % % % % % %     infection11(i)=sum(SymptomaticIncidence(Wave1(i),1:364))*S0+ ...
% % % % % % %         sum(AsymptomaticIncidence(Wave1(i),1:364))*S0;
% % % % % % % end
% % % % % % % NoSexAttackRate=mean(infection11/S0);
% % % % % % % Percentage=(OverallAttackRate-NoSexAttackRate)/OverallAttackRate
% % % % % % % 
% % % % % % % SEM1 = std((infection1(1,:)-infection11(1,:))./infection1(1,:))/sqrt(length((infection1(1,:)-infection11(1,:))./infection1(1,:)));
% % % % % % % ts1 = tinv([0.025  0.975],length((infection1(1,:)-infection11(1,:))./infection1(1,:))-1);
% % % % % % % CI1 = mean((infection1(1,:)-infection11(1,:))./infection1(1,:)) + ts1*SEM1
% % % % % % % 
% % % % % % % %% Plotting symptomatic incidence during first and second waves
% % % % % % % % all outbreak curves during first wave
% % % % % % % for jj=1:length(Wave1)
% % % % % % % plot(SymptomaticIncidence(Wave1(jj),1:364)'*S0,'color',[110 210 220]./255)
% % % % % % % hold on
% % % % % % % end
% % % % % % % 
% % % % % % % % average of all outbreak curves during first wave
% % % % % % % x1=1:364;
% % % % % % % W11=0;
% % % % % % % for j=1:364
% % % % % % %     for jj=1:length(Wave1)
% % % % % % %         W11=(SymptomaticIncidence(Wave1(jj),j)*S0+ W11);
% % % % % % %     end
% % % % % % %     W1(j)=W11/length(Wave1);
% % % % % % %     W11=0;
% % % % % % % end
% % % % % % % hold all
% % % % % % % plot(x1,W1,'r','LineWidth',2)
% % % % % % % 
% % % % % % % % all outbreak curves during second wave
% % % % % % % x2=365:731;
% % % % % % % for jj=1:length(Wave2)
% % % % % % % plot(x2,SymptomaticIncidence(Wave2(jj),365:end)'*S0,'color',[169 170 210]./255)
% % % % % % % hold on
% % % % % % % end
% % % % % % % 
% % % % % % % % average of all outbreak curves during second wave
% % % % % % % W22=0;
% % % % % % % for j=365:731
% % % % % % %     for jj=1:length(Wave2)
% % % % % % %         W22=(SymptomaticIncidence(Wave2(jj),j)*S0+ W22);
% % % % % % %     end
% % % % % % %     W2(j)=W22/length(Wave2);
% % % % % % %     W22=0;
% % % % % % % end
% % % % % % % plot(x2,W2(1,365:end),'r','LineWidth',2)
% % % % % % % xlim([56,731]);
% % % % % % % set(gca,'fontsize',12);
% % % % % % % set(gca,'XTick',[0:112:731]);
% % % % % % % set(gca,'XTickLabel',str2mat('0','16','32','48','64','80','96'));


% Revised Code April 2017 for revision of Scientific Reports paper