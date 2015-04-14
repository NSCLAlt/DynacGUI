function anasenhist(varargin)
%Takes a distribution file at the Anasen target position (generalize later)
%and spits out a histogram
filename='Particle Distributions/Anasen target.dst';
filetext=strrep(filename,'_','\_');

rfqfreq=1e6*dlmread(filename,'',[0 2 0 2]); %file frequency in Hz
rfqperiod=1/rfqfreq;

dist=dlmread(filename,'',1,0);
rpenergy=dist(1,6);
time=(dist(:,5)/pi)*(rfqperiod/2)*10^9; %Time in ns, not radians

showlimits=1;
%Cut on time
tcut=1;
if tcut==1
       threshhold = 55.0; %Time threshhold (ns) on which beam is removed
       abstime = abs(time);
       timecut = find(abstime>threshhold);
       dist(timecut,:)=[];
       time(timecut,:)=[];
end

%bunchlimit=10^9*rfqperiod/2;
bunchlimit=6;%Extent, in ns of central bunch

%Show Particles
figure;
plot(time,100*(dist(:,6)-rpenergy)/rpenergy,'r.');
if showlimits==1
    line([-bunchlimit -bunchlimit],get(gca,'ylim'));
    line([bunchlimit bunchlimit],get(gca,'ylim'));
end
xlabel('dt (ns)');
ylabel('dE/E [%]');
title(filetext);

%Show Histogram
figure;
binwidth = 1; %Histogram bin width in ns
trange=min(time):binwidth:max(time);
counts=histc(time,trange);
bar(trange,counts/max(counts),'histc');
xlabel('dt (ns)');

%Show limits
if showlimits==1
line([-bunchlimit -bunchlimit],get(gca,'ylim'));
line([bunchlimit bunchlimit],get(gca,'ylim'));
end

%Generate Summary Text
nparts=histc(time,[-10^12,-bunchlimit,bunchlimit,10^12]);
ntotal=nparts(1)+nparts(2)+nparts(3);
summarytext=sprintf('%g in bunch (%g%%)\n%g outside (%g%%)',nparts(2),...
    (nparts(2)/ntotal)*100,nparts(1)+nparts(3),...
    (nparts(1)+nparts(3))*100/ntotal);
        ylim=get(gca,'ylim');
        xlim=get(gca,'xlim');
text(xlim(2),ylim(2),summarytext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',8);

if nargin>=1
    titlestring=sprintf([filetext '\n%s'],varargin{1});
    title(titlestring);
else
title(filetext);
end

