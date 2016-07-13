function varargout=emitplot(freqlist,varargin)
%
%   Plotting routine for DynacGUI
%
%Plots the entire contents of a DYNAC "emit.plot" file if there are no
%input arguments.  If there are two input arguments, plots ONE graph starting
%at the offset given by the second input.
%Input arguments - freqeuncy list, file position at start, selection number
%of desired graph, emit.plot directory.
%
%  This software is Copyright by the Board of Trustees of Michigan
%  State University (c) Copyright 2015.
%  
%   Contact Information:
%    Facility for Rare Isotope Beam
%    Michigan State University
%    East Lansing, MI 48824-1321
%    http://frib.msu.edu
%  
% 
%   Update Log:
%
%11/18/13 - Added phase/energy histograms and RMS widths
%3/24/14 - Added autoscaling to plots. (Click on a plot and the axes
%           auto scale to include all particles)
%4/8/14 - Modified to pass list of frequencies separately
%5/7/14 - Fixed autoscaling of histograms.
%7/7/14 - Added ability to write particle distributions from emittance
%           plots
%7/11/14 - Fixed major error in Dynac output file.  Added ability to dump
%            to COSY
%7/15/14 - Clarified Longitudinal plot label.
%7/23/14 - Realized that emit.plot data has no relative energy reference.
%          Updated code to scan 'dynac.long' for reference particle energy 
%           at plotposition when producing particle distibution files.
%7/30/14 - Fixed bug related to carriage returns on MACs
%8/15/14 - Added ability to export TRACK files
%8/20/14 - Bugfixes for TRACK export routine
%9/12/14 - Added menu feature to display beam properties at plot position
%9/24/14 - Corrected bug with multi charge state plots that affected
%           situations where RDBEAM was used.
%        - Squashed another bug in the "output particle distribution"
%           routine
%10/23/14 - Added ability to look for "emit.plot" in arbitrary directory
%10/28/14 - Implemented multi-color graphics for multiple charge state
%           plots.
%11/7/14 - Added auxilliary plots (x and y vs. phase and energy) (Not yet
%           for multi-charge state plots.) (Which means it also doesn't work 
%           for post RFQ multiperiod plots.)
%        - Added phase histogram
%11/10/14 - Added auxilliary plots for multi-charge state plots.
%         - Added active controls for bin width and acceptance window
%2/19/15  - Renamed "Tools" menu "DynacGUI Tools"
%2/25/15  - Added color coded element position indicators.
%3/13/15  - Fixed error when user cancels instead of selecting output
%           distribution name
%3/16/15 - Added dx and dy to beam data display.
%3/25/15 - Added fit line and data to x vs. e plot for single charge state
%           beam.
%        - Fixed ovals not appearing correctly for x vs. y and t vs. E
%        plots.
%3/26/15 - Added P vs. x plot with dispersion and resolution fitting.
%3/30/15 - Fixed "save particle distribution" problems.
%        - Write particle distribution now works for charge states not +1
%        - Also now works for multiple charge state beams
%4/16/15 - Changed realspace text from RMS to sigma.
%        - Removed x/y oval, since it seems to be wrong.
%        - Made dots in multi-charge state plots smaller for consistency
%4/23/15 - Dispersion Plot for multi-charge state beam
%4/24/15 - Fixed serious error in dispersion fitting.
%4/27/15 - This time I think the dispersion is actually correct.
%5/4/15  - Now properly closes the emit.plot file.
%        - Fixed weird bug in multicharge state plot.
%5/18/15 - Corrected dispersion function for right version of dp.
%5/26/15 - Added energy per nucelon to beam data display.
%        - Made resolution number on dispersion plot less wrong. (I hope.)
%7/7/15  - Added support for zone plots
%11/5/15 - Clicking "Phase" label now toggles between degrees and
%nanoseconds.  Still needs some tweaking.
%11/13/15 - Clicking "Energy" label toggles between absolute energy in MeV,
%and relative energy in % and MeV.
%12/16/15 - Clicking labels now maintains FW text in the correct position
%and units.

%   To Do:
%       Throw a more obvious error when requesting data that hasn't been generated to
%       dynac.short by a failed run.  
%       Rescale peoval rather than hiding it.
%       Fix histograms under rescaling.

%If emit.plot directory is not specified, use default
if (nargin>=4)
    epfilename=[varargin{3} filesep 'emit.plot'];
else
    epfilename='emit.plot';
end

if (exist(epfilename,'file')~=2)
    disp('Error: emit.plot not found');
end

plotfile=fopen(epfilename);

%If a single plot is specified, advance to that one, otherwise start from 1
if (nargin>=2)
    fseek(plotfile,varargin{1},'bof');
    plotnumber=varargin{2};
else
    plotnumber=1;
end

while ~feof(plotfile)
    linein=fgetl(plotfile);
    while strcmp(linein,'')
        linein=fgetl(plotfile);
    end
    graphtype=uint16(str2double(strtrim(linein)));
    switch graphtype
        case {1}; %Emittance Plot 
            plottitle=strtrim(fgetl(plotfile));
            plotrpenergy=getplotenergy(plottitle);
            %read in x x' limits
            linein=fgetl(plotfile);
            limits=strsplit(strtrim(linein));
            xlim=[str2num(limits{1}) str2num(limits{2})];
            xplim=[str2num(limits{3}) str2num(limits{4})];
            %Read in x x' fitted oval
            xxpoval=zeros(201,2);
            for i=1:201
                linein=fgetl(plotfile);
                xxpoval(i,:)=str2double(strsplit(strtrim(linein)));
            end
            %Read in actual x x' data
            linein=fgetl(plotfile);
            npart=uint32(str2double(strtrim(linein)));
            x=zeros(1,npart);
            xp=zeros(1,npart);
            for i=1:npart;
                linein=fgetl(plotfile);
                xxp=strsplit(strtrim(linein));
                x(i)=str2double(xxp{1});
                xp(i)=str2double(xxp{2});
            end
            %Read in y y' limits
            linein=fgetl(plotfile);
            limits=strsplit(strtrim(linein));
            ylim=[str2num(limits{1}) str2num(limits{2})];
            yplim=[str2num(limits{3}) str2num(limits{4})];
            %Read in y y' fitted oval
            yypoval=zeros(201,2);
            for i=1:201
                linein=fgetl(plotfile);
                yypoval(i,:)=str2double(strsplit(strtrim(linein)));
            end
            %Read in y y' actual data
            linein=fgetl(plotfile);
            npart=uint32(str2double(strtrim(linein)));
            y=zeros(1,npart);
            yp=zeros(1,npart);
            for i=1:npart;
                linein=fgetl(plotfile);
                yyp=strsplit(strtrim(linein));
                y(i)=str2double(yyp{1});
                yp(i)=str2double(yyp{2});
            end
            linein=fgetl(plotfile); %read and discard redundant xy limits
            linein=fgetl(plotfile);
            %Read in phase and energy limits
            limits=strsplit(strtrim(linein));
            plim=[str2num(limits{1}) str2num(limits{2})];
            elim=[str2num(limits{3}) str2num(limits{4})];
            %Read in phase and energy fitted oval
            peoval=zeros(201,2);
            for i=1:201
                linein=fgetl(plotfile);
                peoval(i,:)=str2double(strsplit(strtrim(linein)));
            end
            %Read in phase and energy data
            linein=fgetl(plotfile);
            npart=uint32(str2double(strtrim(linein)));
            deg=zeros(1,npart);
            energy=zeros(1,npart);
            for i=1:npart;
                linein=fgetl(plotfile);
                pe=strsplit(strtrim(linein));
                deg(i)=str2double(pe{1}); %[degrees]
                energy(i)=str2double(pe{2});
            end
            
            %Generate the figure
            fh=figure('Name',plottitle);
            toolsmenu=uimenu(fh,'Label','DynacGUI Tools');
            wm0=uimenu(toolsmenu,'Label','Show Beam Data',...
                'Callback',{@showdata,plottitle});
            wm1=uimenu(toolsmenu,'Label','Auxiliary Plots');
            wm2=uimenu(toolsmenu,'Label',...
                'Write Particle Distribution to File','Callback',...
                {@write_distribution,x,xp,y,yp,deg,energy,freqlist(plotnumber)},...
                'Accelerator','D','Separator','on');
            wm3=uimenu(toolsmenu,'Label',...
                'Export COSY Distribution File','Callback',...
                {@write_cosy_distribution,x,xp,y,yp,deg,energy,freqlist(plotnumber)});
            wm4=uimenu(toolsmenu,'Label',...
                'Export TRACK Distribution File','Callback',...
                {@write_track_distribution,x,xp,y,yp,deg,energy,freqlist(plotnumber)});
            
            phase=(deg*10^9)/(360*freqlist(plotnumber));%deg -> ns
            plim=(plim*10^9)/(360*freqlist(plotnumber));%deg -> ns
            peoval(:,1)=peoval(:,1).*(10^9/(360*freqlist(plotnumber)));%deg -> ns

            %Auxiliary Plots Menu
            pm0=uimenu(wm1,'Label','X vs. Time','Callback',...
                {@xt_plot,x,phase});
            pm1=uimenu(wm1,'Label','Y vs. Time','Callback',...
                {@yt_plot,y,phase});
            pm2=uimenu(wm1,'Label','X vs. Energy','Callback',...
                {@xe_plot,x,energy});
            pm3=uimenu(wm1,'Label','Y vs. Energy','Callback',...
                {@ye_plot,y,energy});
            pm4=uimenu(wm1,'Label','P vs. x','Callback',...
                {@px_plot,x,energy,plottitle});
            pm5=uimenu(wm1,'Label','Phase / Energy Histogram','Callback',...
                {@p_hist,phase,plottitle});
            
            %Generate the X X' plot
            xxpplot=subplot(2,2,1);
                plot(x,xp,'r.','MarkerSize',3);
                axis([xlim xplim]);
                title('Horizontal Phase Space');
                xlabel('X (cm)');
                ylabel('Px (mrad)');
                grid on;
                hold on;
                plot(xxpoval(:,1),xxpoval(:,2),'-g')
                hold off;
                set(gca,'ButtonDownFcn', @mouseclick_callback);
            %Generate the Y Y' plot
            yypplot=subplot(2,2,2);
                plot(y,yp,'r.','MarkerSize',3);
                axis([ylim yplim]);
                title('Vertical Phase Space');
                xlabel('Y (cm)');
                ylabel('Py (mrad)');
                grid on;
                hold on;
                plot(yypoval(:,1),yypoval(:,2),'-g')
                hold off;
                set(gca,'ButtonDownFcn', @mouseclick_callback);
            %Generate the realspace plot, with profiles
            xyplot=subplot(2,2,3);
                plot(x,y,'r.','MarkerSize',3);
                axis([xlim ylim]);
                title('Real Space');
                xlabel('X (cm)');
                ylabel('Y (cm)');
                grid on;
                hold on;
                %Add histograms and widths
                [xelements,xcenters]=hist(x,30);
                [yelements,ycenters]=hist(y,30);
                xyxhist=plot(xcenters,(xelements/((ylim(2)-ylim(1))*max(xelements)))+ylim(1));
                xyyhist=plot((yelements/((xlim(2)-xlim(1))*max(yelements)))+xlim(1),ycenters);
                profiletext=sprintf('X \\sigma = %g\nY \\sigma = %g',std(x),std(y));
                xyt=text(xlim(2),ylim(2),profiletext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',8);
                %rescale on mouse click
                set(gca,'ButtonDownFcn', {@mouseclick_callback,xyt,xyxhist,xyyhist});
                %plot the ellipse
                %plot(xxpoval(:,1),yypoval(:,1),'g');
                hold off;
            %Generate the phase/energy plot
            teplot=subplot(2,2,4);
                tep.plot=plot(phase,energy,'r.','MarkerSize',3);
                tep.nstates=1;
                axis([plim elim]);
                tep.axes=gca;
                title('Longitudinal Phase Space');
                tep.paxislabel=xlabel('Time (ns)');
                set(tep.paxislabel,'UserData','ns');
                tep.eaxislabel=ylabel('Relative Energy (MeV)');
                set(tep.eaxislabel,'UserData','Rel');
                grid on;
                hold on;                
                %Add histograms and widths
                [pelements,pcenters]=hist(phase,50);
                [eelements,ecenters]=hist(energy,50);
                tep.pephist=plot(pcenters,...
                    (pelements/max(pelements))*.25*(elim(2)-elim(1))+elim(1));
                tep.peehist=plot((eelements/max(eelements))*.25*(plim(2)-plim(1))+plim(1),ecenters);
                tep.peoval=plot(peoval(:,1),peoval(:,2),'-g');
                tep.ewidth=6*std(energy);
                tep.ewidthpct=6*std(100*energy/plotrpenergy);
                tep.pwidth=6*std(phase);
                tep.pwidthdeg=6*std(deg);
                tep.ewidthtext=[num2str(tep.ewidth) ' MeV'];
                tep.pwidthtext=[num2str(tep.pwidth) ' ns'];
                profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
                    tep.pwidthtext,tep.ewidthtext);
                tep.tet=text(plim(2),elim(2),profiletext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',8);
                set(gca,'ButtonDownFcn',...
                    {@mouseclick_callback,tep.tet,tep.pephist,tep.peehist});
                set (tep.paxislabel,'ButtonDownFcn',{@changepaxis,tep,phase,deg});
                set (tep.eaxislabel,...
                        'ButtonDownFcn',{@changeeaxis,tep,energy,plotrpenergy});
                hold off;
            suptitle(plottitle);
            if (nargin>=2) 
                fclose(plotfile);
                return 
            end;
        case 2; %Profile Graph
            disp('Error: Profile Graph not yet implimented')
            fclose(plotfile);
            return;
        case 3; %XY Envelope Plot
            plottitle=strtrim(fgetl(plotfile));
            limits=strsplit(strtrim(fgetl(plotfile)));
            zlim=[str2num(limits{1}) str2num(limits{2})];
            xlim=[str2num(limits{3}) str2num(limits{4})];
            npoints=uint32(str2double(strtrim(fgetl(plotfile))));
            xenv=[];
            zpos=[];
            for i=1:npoints;
                linein=fgetl(plotfile);
                xz=strsplit(strtrim(linein));
                zpos(i)=str2double(xz{1});
                xenv(i)=str2double(xz{2});             
            end
            npoints=uint32(str2double(strtrim(fgetl(plotfile))));
            yenv=[];
            for i=1:npoints;
                linein=fgetl(plotfile);
                yz=strsplit(strtrim(linein));
                yenv(i)=str2double(yz{2});
            end
            fh=figure('Name',plottitle);
            plot(zpos,xenv/2,'-r',zpos,yenv/2,'-g');
                title(plottitle);
                xlabel('Z position(m)');
                ylabel('4 RMS half width (cm)');
            if (nargin>=2) 
                fclose(plotfile);
                return 
            end;
        case 4; %dW/W Envelope Plot
            plottitle=strtrim(fgetl(plotfile));
            limits=strsplit(strtrim(fgetl(plotfile)));
            zlim=[str2num(limits{1}) str2num(limits{2})];
            Wlim=[str2num(limits{3}) str2num(limits{4})];
            npoints=uint32(str2double(strtrim(fgetl(plotfile))));
            ud=get(findobj('Tag','generatedgraphs_listbox'),'UserData');
            Wenv=[];
            zpos=[];
            for i=1:npoints;
                linein=fgetl(plotfile);
                wz=strsplit(strtrim(linein));
                zpos(i)=str2double(wz{1});
                Wenv(i)=str2double(wz{2});             
            end
            fh=figure('Name',plottitle);
            plot(zpos,Wenv*.1,'-r');
                title(plottitle);
                xlabel('Z position(m)');
                ylabel('dW/W 4RMS Full Width (%)');
            %Add element positions and dW/W=0 line
            for j=1:length(ud.devarray.end);        
                line([ud.devarray.end(j)-ud.devarray.length(j) ud.devarray.end(j)],...
                [0,0],'Color',ud.devarray.color(j),'LineWidth',5);
            end
            hold on
            plot([0,str2double(limits(2))],[0,0],':k','LineWidth',.1);
            if (nargin>=2) 
                fclose(plotfile);
                return 
            end;
        case 5; %dPhi Envelope Plot
            plottitle=strtrim(fgetl(plotfile));
            limits=strsplit(strtrim(fgetl(plotfile)));
            zlim=[str2num(limits{1}) str2num(limits{2})];
            philim=[str2num(limits{3}) str2num(limits{4})];
            npoints=uint32(str2double(strtrim(fgetl(plotfile))));
            ud=get(findobj('Tag','generatedgraphs_listbox'),'UserData');
            Phienv=[];
            zpos=[];
            for i=1:npoints;
                linein=fgetl(plotfile);
                phiz=strsplit(strtrim(linein));
                zpos(i)=str2double(phiz{1});
                Phienv(i)=str2double(phiz{2});             
            end
            fh=figure('Name',plottitle);
            plot(zpos,Phienv * .91,'-r');
                title(plottitle);
                xlabel('Z position(m)');
                ylabel('Phase Full Width (deg)');
            %Add element positions and dW/W=0 line
            for j=1:length(ud.devarray.end);        
                line([ud.devarray.end(j)-ud.devarray.length(j) ud.devarray.end(j)],...
                [0,0],'Color',ud.devarray.color(j),'LineWidth',5);
            end
            hold on
            plot([0,str2double(limits(2))],[0,0],':k','LineWidth',.1);
            if (nargin>=2) 
                fclose(plotfile);
                return 
            end;
        case {6,11}; %Multi-Charge State Plot or Zone Plot
            fgetl(plotfile);%Indicates plot type?
            fgetl(plotfile);%Indicates charge state?
            plottitle=strtrim(fgetl(plotfile));
            plotrpenergy=getplotenergy(plottitle);
            %read in x x' limits
            linein=fgetl(plotfile);
            limits=strsplit(strtrim(linein));
            xlim=[str2num(limits{1}) str2num(limits{2})];
            xplim=[str2num(limits{3}) str2num(limits{4})];
            %Read in x x' fitted oval
            xxpoval=zeros(201,2);
            for i=1:201
                linein=fgetl(plotfile);
                xxpoval=[xxpoval;str2double(strsplit(strtrim(linein)))];
            end
            %Read in actual x x' data
            linein=fgetl(plotfile);
            npart=uint32(str2double(strtrim(linein)));
            x=zeros(1,npart);
            xp=zeros(1,npart);
            xchg=zeros(1,npart);
            for i=1:npart;
                linein=fgetl(plotfile);
                xxp=strsplit(strtrim(linein));
                x(i)=str2double(xxp{1});
                xp(i)=str2double(xxp{2});
                xchg(i)=str2double(xxp{3});
            end
            %Read in y y' limits
            linein=fgetl(plotfile);
            limits=strsplit(strtrim(linein));
            ylim=[str2num(limits{1}) str2num(limits{2})];
            yplim=[str2num(limits{3}) str2num(limits{4})];
            %Read in y y' fitted oval
            yypoval=[];
            for i=1:201
                linein=fgetl(plotfile);
                yypoval=[yypoval;str2double(strsplit(strtrim(linein)))];
            end
            %Read in y y' actual data
            linein=fgetl(plotfile);
            npart=uint32(str2double(strtrim(linein)));
            y=zeros(1,npart);
            yp=zeros(1,npart);
            ychg=zeros(1,npart);
            for i=1:npart;
                linein=fgetl(plotfile);
                yyp=strsplit(strtrim(linein));
                y(i)=str2double(yyp{1});
                yp(i)=str2double(yyp{2});
                ychg(i)=str2double(yyp{3});
            end
            linein=fgetl(plotfile); %read and discard redundant xy limits
            linein=fgetl(plotfile);
            %Read in phase and energy limits
            limits=strsplit(strtrim(linein));
            plim=[str2num(limits{1}) str2num(limits{2})];
            elim=[str2num(limits{3}) str2num(limits{4})];
            %Read in phase and energy fitted oval
            peoval=[];
            for i=1:201
                linein=fgetl(plotfile);
                peoval=[peoval;str2double(strsplit(strtrim(linein)))];
            end
            %Read in phase and energy data
            linein=fgetl(plotfile);
            npart=uint32(str2double(strtrim(linein)));
            deg=zeros(1,npart);
            energy=zeros(1,npart);
            pechg=zeros(1,npart);
            for i=1:npart;
                linein=fgetl(plotfile);
                pe=strsplit(strtrim(linein));
                deg(i)=str2double(pe{1});
                energy(i)=str2double(pe{2});
                pechg(i)=str2double(pe{3});
            end
            
            %Generate the figure
            fh=figure('Name',plottitle);
            chgvals=unique(xchg);
            if graphtype==11
                chgvals=circshift(chgvals,[0,-1]);
            end
            nstates=length(chgvals);
            colors=colormap(hsv(nstates));
            toolsmenu=uimenu(fh,'Label','DynacGUI Tools');
            wm0=uimenu(toolsmenu,'Label','Show Beam Data',...
                'Callback',{@showdata,plottitle});
            wm1=uimenu(toolsmenu,'Label','Auxiliary Plots');
            %REACTIVATE THESE WHEN (if?) MULTI-CHARGE STATE EXPORT IMPLIMENTED
            wm2=uimenu(toolsmenu,'Label',...
                'Write Particle Distribution to File','Callback',...
                {@write_distribution,x,xp,y,yp,deg,energy,freqlist(plotnumber),xchg},...
                'Accelerator','D','Separator','on');
%            wm3=uimenu(toolsmenu,'Label',...
%                'Export COSY Distribution File','Callback',...
%                {@write_cosy_distribution,x,xp,y,yp,phase,energy,freqlist(plotnumber)});
%            wm4=uimenu(toolsmenu,'Label',...
%                'Export TRACK Distribution File','Callback',...
%                {@write_track_distribution,x,xp,y,yp,phase,energy,freqlist(plotnumber)});

            phase=(deg*10^9)/(360*freqlist(plotnumber)); %deg -> ns
            plim=(plim*10^9)/(360*freqlist(plotnumber)); %deg -> ns
            peoval(:,1)=peoval(:,1).*(10^9/(360*freqlist(plotnumber)));%deg -> ns
            
            %Auxiliary Plots Menu
            pm0=uimenu(wm1,'Label','X vs. Time','Callback',...
                {@xt_plot,x,phase,xchg});
            pm1=uimenu(wm1,'Label','Y vs. Time','Callback',...
                {@yt_plot,y,phase,ychg});
            pm2=uimenu(wm1,'Label','X vs. Energy','Callback',...
                {@xe_plot,x,energy,xchg});
            pm3=uimenu(wm1,'Label','Y vs. Energy','Callback',...
                {@ye_plot,y,energy,ychg});
            pm4=uimenu(wm1,'Label','P vs. x','Callback',...
                {@px_plot,x,energy,plottitle,xchg});
            pm5=uimenu(wm1,'Label','Phase / Energy Histogram','Callback',...
                {@p_hist,phase,plottitle});
            
            %Generate the X X' plot
            xxpplot=subplot(2,2,1);
                %scatter(x,xp,1,xchg,'filled');
                for j=1:nstates
                    chindex=find(xchg==chgvals(j));
                    scatter(x(chindex),xp(chindex),1,colors(j,:),'filled');
                    hold on
                end
                axis([xlim xplim]);
                title('Horizontal Phase Space');
                xlabel('X (cm)');
                ylabel('Px (mrad)');
                grid on;
                hold on;
                plot(xxpoval(:,1),xxpoval(:,2),'-g')
                hold off;
                set(gca,'ButtonDownFcn', @mouseclick_callback);
            %Generate the Y Y' plot
            yypplot=subplot(2,2,2);
                %plot(y,yp,'.','MarkerSize',3);
                for j=1:nstates
                    chindex=find(ychg==chgvals(j));
                    yyph(j)=scatter(y(chindex),yp(chindex),1,colors(j,:),'filled');
                    hold on
                end
                %Generate the legend
                if nstates>1
                    legtext=strtrim(cellstr(num2str(chgvals'))');
                    if graphtype==11 %Zone Plots only
                        legtext(end)=strcat('>',legtext(end-1));
                        legtext(1:end-1)=strcat('<',legtext(1:end-1));
                    end
                    leg=legend(legtext);
                    s1=get(leg,'Children');
                    s2=[];
                    s2=findobj(s1,{'type','patch','-or','type','line'});
                    for m=1:length(s2)
                        set(s2(m),'markersize',3);
                    end
                end
                axis([ylim yplim]);
                title('Vertical Phase Space');
                xlabel('Y (cm)');
                ylabel('Py (mrad)');
                grid on;
                hold on;
                plot(yypoval(:,1),yypoval(:,2),'-g')
                hold off;
                set(gca,'ButtonDownFcn', @mouseclick_callback);
            %Generate the realspace plot, with profiles
            xyplot=subplot(2,2,3);
                %plot(x,y,'r.','MarkerSize',3);
                for j=1:nstates
                    chindex=find(xchg==chgvals(j));
                    scatter(x(chindex),y(chindex),1,colors(j,:),'filled');
                    hold on
                end
                %scatter(x,y,1,xchg,'filled');
                axis([xlim ylim]);
                title('Real Space');
                xlabel('X (cm)');
                ylabel('Y (cm)');
                grid on;
                hold on;
                %Add histograms and widths
                [xelements,xcenters]=hist(x,30);
                [yelements,ycenters]=hist(y,30);
                xyxhist=plot(xcenters,(xelements/((ylim(2)-ylim(1))*max(xelements)))+ylim(1));
                xyyhist=plot((yelements/((xlim(2)-xlim(1))*max(yelements)))+xlim(1),ycenters);
                profiletext=sprintf('X \\sigma = %g\nY \\sigma = %g',std(x),std(y));
                xyt=text(xlim(2),ylim(2),profiletext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',8);
                %rescale on mouse click
                set(gca,'ButtonDownFcn', {@mouseclick_callback,xyt,xyxhist,xyyhist});
                %Plot the ellipse
                %plot(xxpoval(:,1),yypoval(:,1),'g');
                hold off;
            %Generate the phase/energy plot
            teplot=subplot(2,2,4);
                %plot(phase,energy,'r.','MarkerSize',3);
                %scatter(phase,energy,1,pechg,'filled');
                tep.nstates=nstates;
                for j=1:nstates
                    tep.chindex{j}=find(xchg==chgvals(j));
                    tep.plot(j)=scatter(phase(tep.chindex{j}),...
                        energy(tep.chindex{j}),1,colors(j,:),'filled');
                    hold on
                end
                axis([plim elim]);
                tep.axes=gca;
                title('Longitudinal Phase Space');
                tep.paxislabel=xlabel('Time (ns)');
                set(tep.paxislabel,'UserData','ns');
                tep.eaxislabel=ylabel('Relative Energy (MeV)');
                set(tep.eaxislabel,'UserData','Rel');
                grid on;
                hold on;
                %Add histograms and widths
                [pelements,pcenters]=hist(phase,50);
                [eelements,ecenters]=hist(energy,50);
                tep.pephist=plot(pcenters,(pelements/max(pelements))*.25*(elim(2)-elim(1))+elim(1));
                tep.peehist=plot((eelements/max(eelements))*.25*(plim(2)-plim(1))+plim(1),ecenters);
                tep.peoval=plot(peoval(:,1),peoval(:,2),'-g') ;
                tep.ewidth=6*std(energy);
                tep.ewidthpct=6*std(100*energy/plotrpenergy);
                tep.pwidth=6*std(phase);
                tep.pwidthdeg=6*std(deg);
                tep.ewidthtext=[num2str(6*std(energy)) ' MeV'];
                tep.pwidthtext=[num2str(6*std(phase)) ' ns'];
                profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
                    tep.pwidthtext,tep.ewidthtext);
                tep.tet=text(plim(2),elim(2),profiletext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',8);
                set(gca,'ButtonDownFcn', {@mouseclick_callback,tep.tet,tep.pephist,tep.peehist});
                set (tep.paxislabel,'ButtonDownFcn',{@changepaxis,tep,phase,deg});
                set (tep.eaxislabel,...
                        'ButtonDownFcn',{@changeeaxis,tep,energy,plotrpenergy});                
                hold off;
            suptitle(plottitle);
            if (nargin>=2) 
                %If we're only plotting one graph, clean up and exit.
                fclose(plotfile);
                return 
            end;
    end
    plotnumber=plotnumber+1;
end

fclose(plotfile);

function tep=changepaxis(~,~,tep,phase,deg)
    paxistype=get(tep.paxislabel,'UserData');
    eaxistype=get(tep.eaxislabel,'UserData');
    if strcmp(eaxistype,'Pct')
        tep.ewidthtext=[num2str(tep.ewidthpct) ' %'];
    else
        tep.ewidthtext=[num2str(tep.ewidth) ' MeV'];
    end
    set(tep.axes,'XLimMode','auto');
        if strcmp(paxistype,'ns')
            set(tep.peehist,'Visible','off');
            set(tep.pephist,'Visible','off');
            set(tep.peoval,'Visible','off');
            if tep.nstates==1
                set(tep.plot,'Xdata',deg);
                tep.pwidthtext=[num2str(tep.pwidthdeg) ' deg'];
            else
                for j=1:tep.nstates
                    set(tep.plot(j),'Xdata',deg(tep.chindex{j}))
                end
                tep.pwidthtext=[num2str(tep.pwidthdeg) ' deg'];
            end
            set(tep.paxislabel,'String','Phase (deg)');
            set(tep.paxislabel,'UserData','deg');      
        else
            if strcmp(eaxistype,'Rel')
                set(tep.peehist,'Visible','on');
                set(tep.pephist,'Visible','on');
                set(tep.peoval,'Visible','on');
            end
            if tep.nstates==1
                set(tep.plot,'Xdata',phase);
                tep.pwidthtext=[num2str(tep.pwidth) ' ns'];
            else
                for j=1:tep.nstates
                    set(tep.plot(j),'Xdata',phase(tep.chindex{j}))                    
                end
                tep.pwidthtext=[num2str(tep.pwidth) ' ns'];
            end
            set(tep.paxislabel,'String','Time (ns)');
            set(tep.paxislabel,'UserData','ns');
        end
        profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
                    tep.pwidthtext,tep.ewidthtext); 
        plim=xlim;
        elim=ylim;
        set(tep.tet,'Position',[plim(2) elim(2)]) ;
        set(tep.tet,'String',profiletext);
        
function tep=changeeaxis(~,~,tep,energy,rpenergy)
    paxistype=get(tep.paxislabel,'UserData');
    eaxistype=get(tep.eaxislabel,'UserData');
    if strcmp(paxistype,'ns')
        tep.pwidthtext=[num2str(tep.pwidth) ' ns'];
    else
        tep.pwidthtext=[num2str(tep.pwidthdeg) ' deg'];
    end
    set(tep.axes,'YLimMode','auto');
        if strcmp(eaxistype,'Rel')
            %Rel->Percent
            set(tep.peehist,'Visible','off');
            set(tep.pephist,'Visible','off');
            set(tep.peoval,'Visible','off');
            pctdata=100*(energy/rpenergy);
            if tep.nstates==1
                set(tep.plot,'Ydata',pctdata);
                tep.ewidthtext=[num2str(tep.ewidthpct) ' %'];
            else
                for j=1:tep.nstates
                    set(tep.plot(j),'Ydata',pctdata(tep.chindex{j}));                    
                end
                tep.ewidthtext=[num2str(tep.ewidthpct) ' %'];
            end
            set(tep.eaxislabel,'String','dW/W (%)');
            set(tep.eaxislabel,'UserData','Pct');
        elseif strcmp(eaxistype,'Pct')
            %Percent->Abs
            if tep.nstates==1
                set(tep.plot,'Ydata',energy+rpenergy);
                tep.ewidthtext=[num2str(tep.ewidth) ' MeV'];
            else
                for j=1:tep.nstates
                    set(tep.plot(j),'Ydata',rpenergy+energy(tep.chindex{j}))                    
                end
                tep.ewidthtext=[num2sr(tep.ewidth) 'MeV'];
            end
            set(tep.eaxislabel,'String','Energy (MeV)');
            set(tep.eaxislabel,'UserData','Abs');
        else
            %Abs->Rel
            if strcmp(paxistype,'ns')
                set(tep.peehist,'Visible','on');
                set(tep.pephist,'Visible','on');
                set(tep.peoval,'Visible','on');
            end
            if tep.nstates==1
                set(tep.plot,'Ydata',energy);
            else
                for j=1:tep.nstates
                    set(tep.plot(j),'Ydata',energy(tep.chindex{j}))
                end
            end
            set(tep.eaxislabel,'String','Relative Energy (MeV)');
            set(tep.eaxislabel,'UserData','Rel');
        end   
        profiletext=sprintf('Phase 3\\sigma FW: %s\nEnergy 3\\sigma FW: %s\n',...
             tep.pwidthtext,tep.ewidthtext); 
        plim=xlim;
        elim=ylim;
        set(tep.tet,'Position',[plim(2) elim(2)])
        set(tep.tet,'String',profiletext);

function hout=suptitle(str, fs)
%SUPTITLE Puts a title above all subplots.
%	SUPTITLE('text') adds text to the top of the figure
%	above all subplots (a "super title"). Use this function
%	after all subplot commands.

% This file is from pmtk3.googlecode.com


%PMTKauthor Drea Thomas  
%PMTKdate June 15, 1995
%PMTKemail drea@mathworks.com

% Warning: If the figure or axis units are non-default, this
% will break.

% Parameters used to position the supertitle.

% Amount of the figure window devoted to subplots
plotregion = .92;

% Y position of title in normalized coordinates
titleypos  = .95;

% Fontsize for supertitle
if nargin < 2
  fs = get(gcf,'defaultaxesfontsize')+4;
end

% Fudge factor to adjust y spacing between subplots
fudge=1;

haold = gca;
figunits = get(gcf,'units');

% Get the (approximate) difference between full height (plot + title
% + xlabel) and bounding rectangle.

	if (~strcmp(figunits,'pixels')),
		setings(gcf,'units','pixels');
		pos = get(gcf,'position');
		setings(gcf,'units',figunits);
    else
		pos = get(gcf,'position');
	end
	ff = (fs-4)*1.27*5/pos(4)*fudge;

        % The 5 here reflects about 3 characters of height below
        % an axis and 2 above. 1.27 is pixels per point.

% Determine the bounding rectange for all the plots

h = findobj(gcf,'Type','axes');  

max_y=0;
min_y=1;

oldtitle =0;
for i=1:length(h),
	if (~strcmp(get(h(i),'Tag'),'suptitle')),
		pos=get(h(i),'pos');
		if (pos(2) < min_y), min_y=pos(2)-ff/5*3;end;
		if (pos(4)+pos(2) > max_y), max_y=pos(4)+pos(2)+ff/5*2;end;
    else
		oldtitle = h(i);
	end
end

if max_y > plotregion,
	scale = (plotregion-min_y)/(max_y-min_y);
	for i=1:length(h),
		pos = get(h(i),'position');
		pos(2) = (pos(2)-min_y)*scale+min_y;
		pos(4) = pos(4)*scale-(1-scale)*ff/5*3;
		set(h(i),'position',pos);
	end
end

np = get(gcf,'nextplot');
set(gcf,'nextplot','add');
if (oldtitle),
	delete(oldtitle);
end
ha=axes('pos',[0 1 1 1],'visible','off','Tag','suptitle');
ht=text(.5,titleypos-1,str);set(ht,'horizontalalignment','center','fontsize',fs);
set(gcf,'nextplot',np);
axes(haold);
if nargout,
	hout=ht;
end

function y = rms(x, dim)
%RMS    Root mean squared value.
if nargin==1
  y = sqrt(mean(x .* conj(x)));
else
  y = sqrt(mean(x .* conj(x), dim));
end

function mouseclick_callback(gcbo, ~, varargin)
    origylim=get(gca,'ylim');
    origxlim=get(gca,'xlim');
    origywid=origylim(2)-origylim(1);
    origxwid=origxlim(2)-origxlim(1);
    axis auto;
    if nargin>=3
        ylim=get(gca,'ylim');
        xlim=get(gca,'xlim');
        newxwid=xlim(2)-xlim(1);
        newywid=ylim(2)-ylim(1);
        set(varargin{1},'Position',[xlim(2) ylim(2)])
    end
    if nargin >=4 %reset histogram on x axis
        yscale=newywid/origywid;
        newydata=yscale*(get(varargin{2},'ydata')+origylim(1))-ylim(1);
        set(varargin{2},'ydata',newydata);
    end
    if nargin >=5 %reset histogram on y axis
        xscale=newxwid/origxwid;
        newxdata=xscale*(get(varargin{3},'xdata')+origxlim(1))-xlim(1);
        set(varargin{3},'xdata',newxdata);
    end
    
function write_distribution(gcbo, ~, x, xp, y, yp, phase, energy, freq, varargin)
%Write an ouput distribution in Dynac format
%Varargin is xchg - list of charges sorted in the same order as x particles         

    plotname=get(gcbf,'Name');
       
    %Select Output File
    [distfile, distfilepath]=...
        uiputfile(['Particle Distributions' filesep '*.*'],...
        'Name Saved Distribution File',...
        ['Particle Distributions' filesep plotname '.dst']);
    
    if isequal(distfile,0) %user cancels out of file select
        return
    end
    
    readline='';
    longdata=fileread('dynac.long');
    if (nargin==9) %single charge state beam
        %Get energy and charge from 'Dynac.long'
        findexp='Charge state(s\):\s*(\S*)';
        cresult=regexp(longdata,findexp,'tokens','once');
        charges(1:length(x))=str2double(cresult{1});
        findexp=[strrep(plotname,')','\)') '.*?ENERGY:\s*(\S*)'];
        eresult=regexp(longdata,findexp,'tokens');
        refenergy=str2double(eresult{1});
        energy=energy+refenergy; % relative -> MeV
    else %Multi Charge State Beam
        charges=varargin{1};
        %Get energies from 'Dynac.long'
        datastart=regexp(longdata,plotname);
        dl=fopen('dynac.long');
        fseek(dl,datastart,'bof');
        while isempty(regexp(readline,'EMIT','once'))
            readline=fgetl(dl);
        end
        fgetl(dl);
        readline=fgetl(dl);
        eresult=regexp(readline,'\s*\S*\s*\S*\s*\S*\s*(\S*)','tokens','once');
        refenergy=str2double(eresult{1});
        fclose(dl);
        energy=energy+refenergy;
    end
    
    %Write Distribution
    df=fopen([distfilepath distfile],'w');
    %Header Line
    freq=freq*10^-6; %Hz -> MHz
    fprintf(df,'%12d   %18.16f    %22.15f  %22.15f\r\n',length(x),0,freq,refenergy);
    xp = xp*10^-3; % mrad -> rad
    yp = yp*10^-3; % mrad -> rad
    phase=phase*2*pi/360; %deg -> rad
    for i = 1:length(x);
       fprintf(df,...
           '%+12.6E %+12.6E %+12.6E %+12.6E %+12.6E %+12.6E %+12.6E\r\n',...
           x(i),xp(i),y(i),yp(i),phase(i),energy(i),charges(i));
    end
    fclose(df);
    
function write_cosy_distribution(gcbo, eventdata, x, xp, y, yp, phase, energy, freq)
%Write an ouput distribution in COSY format (as defined by Portillo)

    plotname=get(gcbf,'Name');

    %Select Output File
    [distfile,distfilepath]=uiputfile(['Particle Distributions' filesep '*.*'],...
        'Name Saved Distribution File',...
        ['Particle Distributions' filesep plotname '_COSY.pos']);
    
    %Get energy from 'Dynac.long'
    longdata=fileread('dynac.long');
    findexp=[strrep(plotname,')','\)') '.*?ENERGY:\s*(\S*)'];
    eresult=regexp(longdata,findexp,'tokens');
    refenergy=str2double(eresult{1});
     
    %Write Distribution
    df=fopen([distfilepath distfile],'w');
    %Header Lines
    fprintf(df,' %8.7f, PARTICLES, N=0 IS REF PARTICLE----\r\n',...
           length(x)-1);
    fprintf(df,' X A Y B DT DK DG DZ\r\n');
    
    x=x*10^-2; %cm -> m
    y=y*10^-2; %cm -> m
    
    xp = xp*10^-3; % mrad -> rad
    yp = yp*10^-3; % mrad -> rad

    mass=str2double(get(findall(0,'Tag','a_textbox'),'String'));
    gamma = (refenergy+mass*931.494)/(mass*931.494); 
        
    z =  -(gamma/(1+gamma))*phase*2.998e8/(360 * freq); %deg -> m 
    zp = energy; 
    
    for i = 1:length(x);
       fprintf(df,...
           '%+13.7E %+13.7E %+13.7E %+13.7E %+13.7E\r\n%+13.7E %+13.7E %+13.7E 01\r\n',...
           x(i),xp(i),y(i),yp(i),z(i),zp(i),0,0);
    end
    fprintf(df,'END');
    fclose(df);
    
    function write_track_distribution(gcbo, eventdata, x, xp, y, yp, phase, energy, freq)
    %Write an ouput distribution in TRACK format

    plotname=get(gcbf,'Name');
    
    %Select Output File
     [distfile,distfilepath]=uiputfile(['Particle Distributions' filesep '*.*'],...
        'Name Saved Distribution File',...
        ['Particle Distributions' filesep 'read_dis_' plotname '.dst']);
    
    %Get energy,charge, and mass from 'Dynac.long'
    dynaclong=fopen('dynac.long');
    longdata=textscan(dynaclong,'%s','Delimiter','\n');
    masscell= not(cellfun('isempty',strfind([longdata{:}],'mass units:')));
    massstring=longdata{1,1}{masscell,1};
    mresult=regexp(massstring,'mass units: (?<mass>.*) rest mass:','names');
    mass=str2double(mresult.mass);
    cresult=regexp(massstring,'charge (?<charge>.*)','names');
    charge=str2double(cresult.charge);
    plotcell=find(not(cellfun('isempty',strfind([longdata{:}],plotname))));
    ecell=plotcell+8;
    estring=longdata{1,1}{ecell,1};
    eresult=regexp(estring,'ENERGY: (?<energy>.*) \(MeV\)','names');
    refenergy=str2double(eresult.energy);
    fclose(dynaclong);
     
    %Convert Units
    xp = xp*10^-3; %mrad -> rad
    yp = yp*10^-3; %mrad -> rad
    phase = phase*2*pi/360; %deg -> rad
    energy=energy+refenergy; % relative -> total MeV
    gamma = (energy/mass)/931.494+1; %Gamma per particle
    beta = sqrt(gamma.*gamma-1)./gamma; %beta per particle
    
    %Write Distribution
    df=fopen([distfilepath distfile],'w');
    %Header
    fprintf(df,'%23.15d%8g\r\n',refenergy*1000/mass,1); %Energy(keV/u), # of charge states
    fprintf(df,'%8g\r\n',length(x)-1); %number of particles
    fprintf(df,'%23.15e\r\n',charge); %charge state
    for i=1:length(x)
    fprintf(df,'%23.15e%23.15e%23.15e%23.15e%23.15e%23.15e%8g\r\n',...
        x(i), xp(i),...%X and X' in cm and rad
        y(i), yp(i),...%Y and Y' in cm and rad
        phase(i), beta(i), 0);%Relative Phase(rad) and beta
    end
    
    fclose(df);
    
function plotrpenergy=getplotenergy(plotname)
    %Retrieve the energy for a given plot name from "dynac.short"
    
     if ~exist('dynac.short','file')==2
         %If dynac.short doesn't exist, return -1
         plotrpenergy=-1;
         return
     end
     
     dsfile=fopen('dynac.short');
     fileline=fgetl(dsfile);
     while isempty(strfind(fileline,plotname))
         if feof(dsfile)
             plotrpenergy=-1;
             return
         end
         fileline=fgetl(dsfile);
     end
     
     %Skip two lines
     fileline=fgetl(dsfile);
     fileline=fgetl(dsfile);
     
     %READ ALL THE DATA!
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        plotrpenergy=str2double(C{3});

        fclose(dsfile);
         
    
    function showdata(gcbo, ~, title)
        %Show corresponding data from dynac.short for an emittance plot
        
        %Open dynac.short
        try
            dsfile=fopen('dynac.short');
        catch
            disp('Error: dynac.short not found');
            return
        end
        
        %Scan for the plot title
        fileline=fgetl(dsfile);
        while isempty(strfind(fileline,title))
            if feof(dsfile) %Throw an error if end of file is reached w/o finding it
                disp(['Error: Plot data for ' title 'not found']);
                fclose(dsfile);
                return
            end
            fileline=fgetl(dsfile);
        end
        
        %Skip two lines
        fileline=fgetl(dsfile);
        fileline=fgetl(dsfile);
        
        %READ ALL THE DATA!
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.betarp=C{2};
        out.energyrp=C{3};
        out.tofrp=C{4};
        out.energycog=C{5};
        out.tofcog=C{6};
        out.eoffsetcog=C{7};
        out.toffsetcog=C{8};
        fileline=fgetl(dsfile);
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.xcog=C{2};
        out.xpcog=C{3};
        out.ycog=C{4};
        out.ypcog=C{5};
        fileline=fgetl(dsfile);
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.alphax=C{2};
        out.betax=C{3};
        out.alphay=C{4};
        out.betay=C{5};
        out.alphaznskev=C{6};
        out.betaznskev=C{7};
        fileline=fgetl(dsfile);
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.alphazdegkev=C{2};
        out.betazdegkev=C{3};
        out.emitzdegkev=C{4};
        out.freq=C{6};
        fileline=fgetl(dsfile);
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.dphi=C{2};
        out.dw=C{3};
        out.rphie=C{4};
        out.emitznskev=C{5};
        out.particles=C{7};
        fileline=fgetl(dsfile);
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.dx=C{2};
        out.dxp=C{3};
        out.rxxp=C{4};
        out.emitxnorm=C{5};
        out.emitxnon=C{8};
        fileline=fgetl(dsfile);
        C=strsplit(fileline,'\s*',...
            'DelimiterType','RegularExpression');
        out.dy=C{2};
        out.dyp=C{3};
        out.ryyp=C{4};
        out.emitynorm=C{5};
        out.emitynon=C{8};
        
        %Get data from main DynacGUI window
        figtag = 'DynacGUI';
        guifig = findobj(allchild(0),'flat','Tag',figtag);
        guihand=guidata(guifig);
        
        eperu=str2double(out.energyrp)/guihand.settings.A;
        
        %Create output string:
        i=1;
        outstring{i}=['Beam Data for Plot: ' title]; i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['RP Energy: ' out.energyrp ' MeV'];i=i+1;
        outstring{i}=['       RP Energy / nucleon: ' num2str(eperu) ' MeV/u'];i=i+1;
        outstring{i}=['RP Beta: ' out.betarp];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['X-Alpha: ' out.alphax];i=i+1;
        outstring{i}=['X-Beta: ' out.betax ' mm/mrad'];i=i+1;
        outstring{i}=['X Emittance (4 RMS): ',out.emitxnon,' mm.mrad'];i=i+1;
        outstring{i}=['X 1/2 Width (4 RMS): ' out.dx ' mm'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Y-Alpha: ' out.alphay];i=i+1;
        outstring{i}=['Y-Beta: ' out.betay ' mm/mrad'];i=i+1;
        outstring{i}=['Y Emittance (4 RMS): ',out.emitynon,' mm.mrad'];i=i+1;
        outstring{i}=['Y 1/2 Width (4 RMS): ' out.dy ' mm'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Z Emittance (4 RMS, non-normalized): ',out.emitznskev,...
            ' keV.ns'];i=i+1;
        outstring{i}=['Phase 1/2 Width (4 RMS): ',out.dphi, ' degrees'];i=i+1;
        outstring{i}=['Energy 1/2 Width (4 RMS): ',out.dw, ' keV'];i=i+1;
        outstring{i}=' ';i=i+1;
        outstring{i}=['Number of Particles Remaining: ',out.particles];i=i+1;
        
        %Display output string.
        %Original code stolen from:
        %http://www.mathworks.com/matlabcentral/answers/19553-display-window-for-text-file

        f = figure('menu','none','toolbar','none','Name',[title ' data']);
        ph = uipanel(f,'Units','normalized','position',[0.05 0.05 0.9 0.9],...
            'BorderType','none');
        lbh = uicontrol(ph,'style','listbox','Units','normalized','position',...
            [0 0 1 1],'FontSize',9);

        set(lbh,'string',outstring);
        set(lbh,'Value',1);
        set(lbh,'Selected','on');
        
        fclose(dsfile);
        
        function xt_fig=xt_plot(~,~,x,phase,varargin)
            %Plot x vs phase
            xt_fig=figure('Name','X vs. Time');
            if nargin==4
                plot(x,phase,'r.','markersize',5);
            else
                xchg=varargin{1};
                chgvals=unique(xchg);
                nstates=length(chgvals);
                colors=colormap(hsv(nstates));
                for j=1:nstates
                    chindex=find(xchg==chgvals(j));
                    xph(j)=scatter(x(chindex),phase(chindex),5,colors(j,:),'filled');
                    hold on;
                end
                if nstates>1
                    leg=legend(strtrim(cellstr(num2str(chgvals'))'));
                    s1=get(leg,'Children');
                    s2=[];
                    s2=findobj(s1,{'type','patch','-or','type','line'});
                    for m=1:length(s2)
                        set(s2(m),'markersize',3);
                    end
                end
                    
            end
            title('X vs. Time');
            xlabel('X (cm)');
            ylabel('Time (ns)');
            set(gca,'ButtonDownFcn', @mouseclick_callback);
            
        function yt_fig=yt_plot(~,~,y,phase,varargin)
            %Plot y vs phase
            yt_fig=figure('Name','Y vs. Time');
            if nargin==4
                plot(y,phase,'r.','markersize',5);
            else
                ychg=varargin{1};
                chgvals=unique(ychg);
                nstates=length(chgvals);
                colors=colormap(hsv(nstates));
                for j=1:nstates
                    chindex=find(ychg==chgvals(j));
                    yph(j)=scatter(y(chindex),phase(chindex),5,colors(j,:),'filled');
                    hold on;
                end
                if nstates>1
                    leg=legend(strtrim(cellstr(num2str(chgvals'))'));
                    s1=get(leg,'Children');
                    s2=[];
                    s2=findobj(s1,{'type','patch','-or','type','line'});
                    for m=1:length(s2)
                        set(s2(m),'markersize',3);
                    end
                end
            end
            title('Y vs. Time');
            xlabel('Y (cm)');
            ylabel('Time (ns)');
            set(gca,'ButtonDownFcn', @mouseclick_callback);
            
        function xe_fig=xe_plot(~,~,x,energy,varargin)
            %Plot x vs energy
            xe_fig=figure('Name','X vs. Energy');
            
            if nargin==4 %Not a multi charge state beam
                plot(x,energy,'r.','markersize',5);
                
                %Find fit line
                fitcoeffs=polyfit(x,energy,1); %Coeffs in MeV/cm and MeV
                fitline=fitcoeffs(1).*x+fitcoeffs(2);
                disptext=sprintf('Slope: %s keV/cm\nInverse Slope: %s cm/keV',...
                    num2str(fitcoeffs(1)*1000), num2str(1/fitcoeffs(1)*1000));
                
                %Plot line and caption
                hold on;
                plot(x,fitline, '-');
                xlim=get(gca,'xlim');
                ylim=get(gca,'ylim');
                text(xlim(2),ylim(2),disptext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',10);
                hold off;
                
            else %This IS a multi charge state beam.
                xchg=varargin{1};
                chgvals=unique(xchg);
                nstates=length(chgvals);
                colors=colormap(hsv(nstates));
                for j=1:nstates
                    chindex=find(xchg==chgvals(j));
                    xen(j)=scatter(x(chindex),energy(chindex),5,colors(j,:),'filled');
                    hold on;
                end
                if nstates>1
                    leg=legend(strtrim(cellstr(num2str(chgvals'))'));
                    s1=get(leg,'Children');
                    s2=[];
                    s2=findobj(s1,{'type','patch','-or','type','line'});
                    for m=1:length(s2)
                        set(s2(m),'markersize',3);
                    end
                end
            end
            title('X vs. Energy');
            xlabel('X (cm)');
            ylabel('Relative Energy (MeV)');
            set(gca,'ButtonDownFcn', @mouseclick_callback);
            
        function ye_fig=ye_plot(~,~,y,energy,varargin)
            %Plot y vs energy
            ye_fig=figure('Name','Y vs. Energy');
            if nargin==4 %Single Charge State Beam
                plot(y,energy,'r.','markersize',5);
            else %Multiple Charge State Beam
                ychg=varargin{1};
                chgvals=unique(ychg);
                nstates=length(chgvals);
                colors=colormap(hsv(nstates));
                for j=1:nstates
                    chindex=find(ychg==chgvals(j));
                    xph(j)=scatter(y(chindex),energy(chindex),5,colors(j,:),'filled');
                    hold on;
                end
                if nstates>1
                    leg=legend(strtrim(cellstr(num2str(chgvals'))'));
                    s1=get(leg,'Children');
                    s2=[];
                    s2=findobj(s1,{'type','patch','-or','type','line'});
                    for m=1:length(s2)
                        set(s2(m),'markersize',3);
                    end
                end
            end
            title('Y vs. Energy');
            xlabel('Y (cm)');
            ylabel('Relative Energy (MeV)');
            set(gca,'ButtonDownFcn', @mouseclick_callback);
            
function px_fig=px_plot(~,~,x,energy,plottitle,varargin)
        %Plot x vs Momentum
            
        %Get info from dynac.short
        %Open dynac.short
        try
            dsfile=fopen('dynac.short');
        catch
            disp('Error: dynac.short not found');
            return
        end
        
        %Scan for the plot title
        line=fgetl(dsfile);
        while isempty(strfind(line,plottitle))
            if feof(dsfile) %Throw an error if end of file is reached w/o finding it
                disp(['Error: Plot data for ' plottitle 'not found']);
                fclose(dsfile);
                return
            end
            line=fgetl(dsfile);
        end
        
        %Skip two lines
        line=fgetl(dsfile);
        line=fgetl(dsfile);
        C=strsplit(line,'\s*',...
            'DelimiterType','RegularExpression');
        beta=str2double(C{2});
        energyrp=str2double(C{3});
        line=fgetl(dsfile);
        line=fgetl(dsfile);
        line=fgetl(dsfile);
        line=fgetl(dsfile);
        C=strsplit(line,'\s*',...
            'DelimiterType','RegularExpression');
        dw=C{3};
        fclose(dsfile); 
        
        gamma=1/sqrt(1-beta^2);
        momentumrp=energyrp*(beta*gamma/(gamma-1)); %in MeV/c
        momentum=energy/beta; % This is actually dp = dW / beta
        pwidth=str2double(dw) / beta; %(dw is in keV)
        dpp=momentum/momentumrp;
            px_fig=figure('Name','Relative Momentum vs. X');
            
            if nargin==5 %Not a multi charge state beam
               % plot(x,dpp*100,'r.','markersize',5);
                 scatter(x,dpp*100,'r.');
                %Find fit line
                fitcoeffs=polyfit(dpp,x,1); %Coeffs in (dp/p)/cm and (dp/p)
                dispersion=0.01*mean(x.*dpp)/mean(dpp.*dpp); 
                        %Dispersion function in meters (m /(dp/p))
                resolution=abs(dispersion/(2*std(x)*0.01));
                    %Resolution function for separation of 2 sigma
                disptext=sprintf(['Dispersion: %s m / (dp/p)\n'...
                    'R (4 RMS): %s '],...
                    num2str(dispersion),num2str(resolution));
                lim=axis;
                
                %Plot line and caption
                hold on;
                plot(x,100*(x-fitcoeffs(2))/fitcoeffs(1),'-'); %Factor of 100 for %
                %plot(x,fitcoeffs(1)*x/100,'-');
                axis(lim);
                xlim=get(gca,'xlim');
                ylim=get(gca,'ylim');
                text(xlim(2),ylim(2),disptext,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','FontSize',10);
                hold off;
                
            else %This IS a multi charge state beam.
                 xchg=varargin{1};
                 chgvals=unique(xchg);
                 nstates=length(chgvals);
                 colors=colormap(hsv(nstates));
                 for j=1:nstates
                     chindex=find(xchg==chgvals(j));
                     xen(j)=scatter(x(chindex),dpp(chindex)*100,5,colors(j,:),'filled');
                     hold on;
                 end
                 if nstates>1 %Create Legend
                     leg=legend(strtrim(cellstr(num2str(chgvals'))'));
                     s1=get(leg,'Children');
                     s2=[];
                     s2=findobj(s1,{'type','patch','-or','type','line'});
                 end
                 lim=axis;
                 legtext=get(leg,'String');
                 for j=1:nstates
                     chindex=find(xchg==chgvals(j));
                     fitcoeffs=polyfit(dpp(chindex),x(chindex),1);
                     dispersion=0.01*mean(x.*dpp)/mean(dpp.*dpp);
                            %Dispersion function in (m/(dp/p))
                     legtext{j}=[legtext{j} ' D: ' num2str(dispersion) ' m'];
                     plot(x(chindex),100*(x(chindex)-fitcoeffs(2))/fitcoeffs(1),'k-');
                 end
                 if nstates>1
                     set(leg,'String',legtext);
                     for m=1:length(s2)
                         set(s2(m),'markersize',3);
                     end
                 end
                 axis(lim)
            end
            title('X vs. Momentum');
            xlabel('X (cm)');
            ylabel('Relative Momentum (dP/P) (%)');
            set(gca,'ButtonDownFcn', @mouseclick_callback);            
            
       function phist_fig=p_hist(~,~,phase,plottitle)
           %Plot Phase Histogram
            phist_fig=figure('Name','Time Histogram');
            ud.phist_ax=axes('Position',[0.13 0.2 0.775 0.715]);
            xlabel('dt (ns)'); 
            ud.phase=phase;
            ud.binwidth = 1; %Default Histogram bin width in ns
            ud.acceptwidth = 12; %Default Acceptance width in ns
            ud.plottitle=plottitle;
            
            %Add Controls to adjust Historgram
            backgroundcolor=get(phist_fig,'Color');
            uicontrol('Style','Text','String','Bin Width (ns)',...
                'BackgroundColor',backgroundcolor,...
                'Position',[30 40 100 20]);
            uicontrol('Style','Edit','String',ud.binwidth,...
                'Position',[130 40 50 20],...
                'Callback',{@change_binwidth});
            uicontrol('Style','Text','String','Accept Width (ns)',...
                'BackgroundColor',backgroundcolor,...
                'Position',[200 40 100 20]);
            uicontrol('Style','Edit','String',ud.acceptwidth,...
                'Position',[320 40 50 20],...
                'Callback',{@change_acceptwidth});
            uicontrol('Style','Text','String','Lower Limit (ns):',...
                'BackgroundColor',backgroundcolor,...
                'Position',[30 5 100 20]);
            ud.ll=uicontrol('Style','Edit','String',-10^12,...
                'Position',[130 5 50 20],...
                'Callback',{@change_lowerlimit});
            uicontrol('Style','Text','String','Upper Limit (ns):',...
                'BackgroundColor',backgroundcolor,...
                'Position',[200 5 100 20]);
            ud.ul=uicontrol('Style','Edit','String',10^12,...
                'Position',[320 5 50 20],...
                'Callback',{@change_upperlimit});
            set(phist_fig,'UserData',ud);
            
            %Calculate histogram
            calchist;  
            xlimits=get(gca,'Xlim');
            ylimits=get(gca,'Ylim');
            ud.lline=line([xlimits(1) xlimits(1)],ylimits,'Color','r');
            ud.uline=line([xlimits(2) xlimits(2)],ylimits,'Color','r');
            set(ud.ll,'String',xlimits(1));
            set(ud.ul,'String',xlimits(2));
            set(phist_fig,'UserData',ud);     
            sumtext;
            
       function calchist
           %Retrieve Data
           ud=get(gcf,'UserData');
           
           %Plot Histogram
           trange=min(ud.phase):ud.binwidth:max(ud.phase);
           counts=histc(ud.phase,trange);
           bar(ud.phist_ax,trange,counts/max(counts),'histc');
           line([-ud.acceptwidth/2 -ud.acceptwidth/2],get(gca,'ylim'));
           line([ud.acceptwidth/2 ud.acceptwidth/2],get(gca,'ylim'));
           title([ud.plottitle ' Histogram']);
           xlabel('nanoseconds');
           ylabel('Normalized Counts');
           
       function sumtext
           ud=get(gcf,'UserData');
           
           %Generate Summary Text
           xlim=get(gca,'Xlim');
           ylim=get(gca,'Ylim');
           lowerlimit=str2double(get(ud.ll,'String'));
           upperlimit=str2double(get(ud.ul,'String'));
           ud.lline=line([lowerlimit lowerlimit],[0 1],'Color','r');
           ud.uline=line([upperlimit upperlimit],[0 1],'Color','r');
           nparts=histc(ud.phase,[lowerlimit,-ud.acceptwidth/2,...
               ud.acceptwidth/2,upperlimit]); %make histogram with 3 bins
           ntotal=nparts(1)+nparts(2)+nparts(3); %total of all particles
           summarytext=sprintf('%g in bunch (%g%%)\n%g outside (%g%%)',nparts(2),...
               (nparts(2)/ntotal)*100,nparts(1)+nparts(3),...
               (nparts(1)+nparts(3))*100/ntotal);
           text(xlim(2),ylim(2),summarytext,'HorizontalAlignment','right',...
               'VerticalAlignment','top','FontSize',8);
           set(gcf,'UserData',ud);

           
       function change_binwidth(src,~)
           %Recalculate histogram for new bin width
           ud=get(gcf,'UserData');
           ud.binwidth=str2double(get(src,'String'));
           set(gcf,'UserData',ud);
           calchist;
           sumtext;
           
       function change_acceptwidth(src,~)
           %Recalculate acceptance width
           ud=get(gcf,'UserData');
           ud.acceptwidth=str2double(get(src,'String'));
           set(gcf,'UserData',ud);
           calchist;
           sumtext;
           
       function change_lowerlimit(src,~)
           %Move lower limit for calculation
           lowerlimit=str2double(get(src,'String'));
           ud=get(gcf,'UserData');
           set(ud.lline,'Xdata',[lowerlimit lowerlimit]);
           calchist;
           sumtext;
           
       function change_upperlimit(src,~)
           %Move lower limit for calculation
           upperlimit=str2double(get(src,'String'));
           ud=get(gcf,'UserData');
           set(ud.uline,'Xdata',[upperlimit upperlimit]);
           calchist;
           sumtext;

           
           